import Foundation
import AVFoundation

// 非 Sendable なバッファを @Sendable クロージャへ一度だけ受け渡すための参照ボックス。
final class BufferBox: @unchecked Sendable {
    private var buffer: AVAudioPCMBuffer?
    init(_ buffer: AVAudioPCMBuffer) { self.buffer = buffer }
    func take() -> AVAudioPCMBuffer? {
        let b = buffer
        buffer = nil
        return b
    }
}

// マイク入力を 16kHz・モノラル・Float32 PCM として収集する。
// Whisper はこの形式（16kHz mono float）を要求するため、ハードウェア形式から変換して蓄積する。
final class AudioRecorder {
    static let targetSampleRate: Double = 16_000

    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private let lock = NSLock()
    private var samples: [Float] = []
    private var isRunning = false
    private var _level: Float = 0   // 直近バッファの音量（0..1 正規化）

    // オーバーレイの波形表示用。録音中にメインスレッドから読む。
    var currentLevel: Float {
        lock.lock(); defer { lock.unlock() }
        return _level
    }

    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: AudioRecorder.targetSampleRate,
        channels: 1,
        interleaved: false
    )!

    enum RecorderError: Error, CustomStringConvertible {
        case invalidInputFormat
        case converterUnavailable
        case engineStartFailed(String)
        var description: String {
            switch self {
            case .invalidInputFormat:      return "マイク入力形式を取得できませんでした（マイク許可を確認してください）"
            case .converterUnavailable:    return "オーディオ変換器を作成できませんでした"
            case .engineStartFailed(let m): return "オーディオエンジン開始失敗: \(m)"
            }
        }
    }

    func start() throws {
        guard !isRunning else { return }

        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw RecorderError.invalidInputFormat
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw RecorderError.converterUnavailable
        }
        self.converter = converter

        lock.lock(); samples.removeAll(keepingCapacity: true); lock.unlock()

        input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.appendConverted(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            throw RecorderError.engineStartFailed(error.localizedDescription)
        }
        isRunning = true
    }

    func stop() -> [Float] {
        guard isRunning else { return [] }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        lock.lock(); let result = samples; samples.removeAll(); lock.unlock()
        return result
    }

    // タップで届いたバッファを 16kHz/mono へ変換して蓄積する（レンダースレッドで呼ばれる）。
    private func appendConverted(_ buffer: AVAudioPCMBuffer) {
        guard let converter else { return }
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1024
        guard let out = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

        // 変換器の入力ブロックは @Sendable。非 Sendable な AVAudioPCMBuffer を
        // 安全に受け渡すため、参照ボックスに包んで一度だけ供給する。
        let box = BufferBox(buffer)
        var convError: NSError?
        converter.convert(to: out, error: &convError) { _, statusPtr in
            guard let b = box.take() else {
                statusPtr.pointee = .noDataNow
                return nil
            }
            statusPtr.pointee = .haveData
            return b
        }
        if convError != nil { return }

        let n = Int(out.frameLength)
        guard n > 0, let ch = out.floatChannelData else { return }
        let ptr = ch[0]

        // RMS（二乗平均平方根）で音量を推定し 0..1 に正規化する。
        var sumSq: Float = 0
        for i in 0..<n { let s = ptr[i]; sumSq += s * s }
        let rms = (n > 0) ? (sumSq / Float(n)).squareRoot() : 0
        let level = min(1, rms * 12)   // ゲイン補正

        lock.lock()
        samples.append(contentsOf: UnsafeBufferPointer(start: ptr, count: n))
        _level = level
        lock.unlock()
    }
}

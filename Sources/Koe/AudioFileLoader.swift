import Foundation
import AVFoundation

// 音声ファイルを 16kHz・モノラル・Float32 の PCM サンプル列として読み込む（検証・テスト用）。
enum AudioFileLoader {
    enum LoadError: Error, CustomStringConvertible {
        case openFailed
        case bufferFailed
        case convertFailed(String)
        var description: String {
            switch self {
            case .openFailed:        return "音声ファイルを開けませんでした"
            case .bufferFailed:      return "オーディオバッファを確保できませんでした"
            case .convertFailed(let m): return "変換に失敗しました: \(m)"
            }
        }
    }

    static func loadSamples16kMono(url: URL) throws -> [Float] {
        guard let file = try? AVAudioFile(forReading: url) else { throw LoadError.openFailed }
        let inFormat = file.processingFormat
        let frames = AVAudioFrameCount(file.length)
        guard frames > 0,
              let inBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: frames) else {
            throw LoadError.bufferFailed
        }
        try file.read(into: inBuffer)

        let target = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: 16_000, channels: 1, interleaved: false)!
        guard let converter = AVAudioConverter(from: inFormat, to: target) else {
            throw LoadError.convertFailed("変換器を作成できません")
        }
        let capacity = AVAudioFrameCount(Double(inBuffer.frameLength) * 16_000 / inFormat.sampleRate) + 1024
        guard let out = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else {
            throw LoadError.bufferFailed
        }

        let box = BufferBox(inBuffer)
        var convError: NSError?
        converter.convert(to: out, error: &convError) { _, statusPtr in
            guard let b = box.take() else { statusPtr.pointee = .noDataNow; return nil }
            statusPtr.pointee = .haveData
            return b
        }
        if let convError { throw LoadError.convertFailed(convError.localizedDescription) }

        let n = Int(out.frameLength)
        guard n > 0, let ch = out.floatChannelData else { return [] }
        return Array(UnsafeBufferPointer(start: ch[0], count: n))
    }
}

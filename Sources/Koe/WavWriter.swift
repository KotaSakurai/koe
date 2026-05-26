import Foundation

// 16kHz・モノラル・16bit PCM の WAV を書き出す（録音内容の診断用）。
enum WavWriter {
    static func write(_ samples: [Float], to url: URL, sampleRate: Int = 16_000) {
        let n = samples.count
        var data = Data()
        func appendLE<T: FixedWidthInteger>(_ v: T) {
            var x = v.littleEndian
            withUnsafeBytes(of: &x) { data.append(contentsOf: $0) }
        }
        let dataSize = n * 2
        data.append("RIFF".data(using: .ascii)!)
        appendLE(UInt32(36 + dataSize))
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        appendLE(UInt32(16))                 // fmt チャンクサイズ
        appendLE(UInt16(1))                  // PCM
        appendLE(UInt16(1))                  // チャンネル数
        appendLE(UInt32(sampleRate))
        appendLE(UInt32(sampleRate * 2))     // バイトレート
        appendLE(UInt16(2))                  // ブロックアライン
        appendLE(UInt16(16))                 // ビット深度
        data.append("data".data(using: .ascii)!)
        appendLE(UInt32(dataSize))
        for s in samples {
            let c = max(-1, min(1, s))
            appendLE(Int16(c * 32767))
        }
        try? data.write(to: url)
    }
}

import Foundation

// 実運用データを後で検証するための構造化ログ（JSON Lines）。
// 1発話 = 1行の JSON。保存先: ~/Library/Application Support/Koe/logs/events.jsonl
enum SessionLogger {
    static var logDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Koe/logs", isDirectory: true)
    }
    static var logFileURL: URL { logDirectory.appendingPathComponent("events.jsonl") }

    private static let lock = NSLock()
    // 設定後は不変で、フォーマットはスレッドセーフ。
    private nonisolated(unsafe) static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    // 1発話分のレコードを追記する。
    static func record(_ fields: [String: Any]) {
        var dict = fields
        dict["ts"] = iso.string(from: Date())
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else { return }
        let line = json + "\n"

        lock.lock(); defer { lock.unlock() }
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        let url = logFileURL
        if let h = try? FileHandle(forWritingTo: url) {
            defer { try? h.close() }
            _ = try? h.seekToEnd()
            try? h.write(contentsOf: Data(line.utf8))
        } else {
            try? Data(line.utf8).write(to: url)
        }
    }
}

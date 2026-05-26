import Foundation

// Whisper の ggml モデル（.bin）の所在管理と初回ダウンロードを担う。
// 保存先: ~/Library/Application Support/Koe/models/
enum WhisperModelKind: String, CaseIterable, Identifiable {
    case base   = "ggml-base.bin"
    case small  = "ggml-small.bin"
    case medium = "ggml-medium.bin"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .base:   return "base（軽量・約148MB）"
        case .small:  return "small（推奨・約466MB）"
        case .medium: return "medium（高精度・約1.5GB）"
        }
    }
    // 完了判定に使う概算の最小バイト数
    var minBytes: Int64 {
        switch self {
        case .base:   return 130_000_000
        case .small:  return 400_000_000
        case .medium: return 1_400_000_000
        }
    }
}

struct ModelDownloader {
    static let baseURLString = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/"

    static var modelsDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Koe/models", isDirectory: true)
    }

    static func localURL(for kind: WhisperModelKind) -> URL {
        modelsDirectory.appendingPathComponent(kind.rawValue)
    }

    static func isAvailable(_ kind: WhisperModelKind) -> Bool {
        let url = localURL(for: kind)
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else { return false }
        return size >= kind.minBytes
    }

    // モデルが無ければダウンロードする。進捗は 0.0〜1.0 を返す。
    static func ensureAvailable(
        _ kind: WhisperModelKind,
        progress: @escaping @Sendable (Double) -> Void,
        completion: @escaping @Sendable (Result<URL, Error>) -> Void
    ) {
        let dest = localURL(for: kind)
        if isAvailable(kind) {
            completion(.success(dest))
            return
        }
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        guard let remote = URL(string: baseURLString + kind.rawValue) else {
            completion(.failure(DownloadError.badURL))
            return
        }
        let delegate = DownloadDelegate(destination: dest, progress: progress, completion: completion)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.downloadTask(with: remote)
        delegate.retain = session
        task.resume()
    }

    enum DownloadError: Error { case badURL, moveFailed }
}

// URLSession のダウンロード進捗・完了を扱うデリゲート。
private final class DownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    let destination: URL
    let progress: @Sendable (Double) -> Void
    let completion: @Sendable (Result<URL, Error>) -> Void
    var retain: URLSession?

    init(destination: URL,
         progress: @escaping @Sendable (Double) -> Void,
         completion: @escaping @Sendable (Result<URL, Error>) -> Void) {
        self.destination = destination
        self.progress = progress
        self.completion = completion
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            progress(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            completion(.success(destination))
        } catch {
            completion(.failure(ModelDownloader.DownloadError.moveFailed))
        }
        retain = nil
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            completion(.failure(error))
            retain = nil
        }
    }
}

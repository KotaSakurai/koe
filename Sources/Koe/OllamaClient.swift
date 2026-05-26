import Foundation

// ローカルの Ollama（http://localhost:11434）へ文字起こし結果を送り、整形済みテキストを得る。
// Ollama 未起動・タイムアウト・空応答などの失敗時は、入力（生の文字起こし）をそのまま返す。
struct OllamaClient {
    let baseURL: URL
    let model: String
    var timeout: TimeInterval = 30

    private static let systemPrompt = """
    あなたは日本語音声入力の校正アシスタントです。次の文字起こしテキストを、意味を変えずに自然な日本語へ整えてください。\
    誤認識の修正、文脈に合った漢字変換、適切な句読点の付与を行い、フィラー（「えーと」「あのー」「えー」等）は取り除きます。\
    新しい情報を加えたり、要約・翻訳・解説をしてはいけません。整えた本文のみを、引用符や前置きなしで出力してください。
    """

    func refine(_ raw: String) async -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return raw }

        do {
            let url = baseURL.appendingPathComponent("api/chat")
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = timeout
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(ChatRequest(
                model: model,
                stream: false,
                messages: [
                    .init(role: "system", content: Self.systemPrompt),
                    .init(role: "user", content: trimmed)
                ],
                options: .init(temperature: 0.2)
            ))

            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                log("整形スキップ（Ollama 応答エラー）: フォールバックで生テキストを使用")
                return trimmed
            }
            let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
            let refined = decoded.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return refined.isEmpty ? trimmed : refined
        } catch {
            log("整形スキップ（Ollama 接続失敗: \(error.localizedDescription)）: 生テキストを使用")
            return trimmed
        }
    }

    // 整形を行う前の簡易疎通確認（任意）。
    func isReachable() async -> Bool {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/tags"))
        req.timeoutInterval = 3
        guard let (_, resp) = try? await URLSession.shared.data(for: req),
              let http = resp as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }

    // MARK: JSON モデル

    private struct ChatRequest: Encodable {
        let model: String
        let stream: Bool
        let messages: [Message]
        let options: Options
        struct Message: Encodable { let role: String; let content: String }
        struct Options: Encodable { let temperature: Double }
    }

    private struct ChatResponse: Decodable {
        let message: Message
        struct Message: Decodable { let role: String; let content: String }
    }
}

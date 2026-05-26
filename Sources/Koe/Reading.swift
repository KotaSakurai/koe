import Foundation

// 日本語テキストの「読み（ふりがな）」をローマ字で取り出すユーティリティ。
// 整形の安全ガードに使う: 読みが変わらない＝漢字の取り違え補正だけ、と判定できる。
enum Reading {
    // 比較用に正規化した読み（小文字・英数字のみ）を返す。
    static func normalized(_ text: String) -> String {
        let cf = text as CFString
        let range = CFRangeMake(0, CFStringGetLength(cf))
        let locale = Locale(identifier: "ja") as CFLocale
        guard let tok = CFStringTokenizerCreate(nil, cf, range,
                                                kCFStringTokenizerUnitWordBoundary, locale) else {
            return ""
        }
        var out = ""
        var type = CFStringTokenizerAdvanceToNextToken(tok)
        while type.rawValue != 0 {
            if let latin = CFStringTokenizerCopyCurrentTokenAttribute(
                tok, kCFStringTokenizerAttributeLatinTranscription) as? String {
                out += latin
            }
            type = CFStringTokenizerAdvanceToNextToken(tok)
        }
        let folded = out.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en"))
        return folded.lowercased().unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init)
            .joined()
    }

    // 2つのテキストの読みが（実質的に）同じか。
    static func isSame(_ a: String, _ b: String) -> Bool {
        let ra = normalized(a)
        let rb = normalized(b)
        guard !ra.isEmpty || !rb.isEmpty else { return true }
        return ra == rb
    }
}

import Foundation
import Security

// DeepSeek API キーなどの秘密情報を macOS Keychain に保存する薄いラッパ。
// UserDefaults（平文）ではなく Keychain に置くことで、設定バックアップ等への漏洩を避ける。
enum Keychain {
    // 1 サービス・1 アカウントの汎用 generic password。
    private static let service = "com.kazumalab.koe"

    // 値を保存する（既存があれば上書き）。空文字なら削除と同義。
    @discardableResult
    static func set(_ value: String, account: String) -> Bool {
        guard !value.isEmpty else { return delete(account: account) }
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        // 既存を消してから入れる（重複登録・更新差分を考えなくて済む）。
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(attrs as CFDictionary, nil) == errSecSuccess
    }

    // 値を読む。無ければ nil。
    static func get(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let s = String(data: data, encoding: .utf8) else { return nil }
        return s
    }

    // 値を削除する（無くても成功扱い）。
    @discardableResult
    static func delete(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

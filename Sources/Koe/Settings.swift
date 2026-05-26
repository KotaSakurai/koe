import Foundation

// ユーザー設定（UserDefaults 永続化）。SwiftUI 側は @AppStorage で同じキーを束縛する。
enum SettingsKey {
    static let refineEnabled  = "koe.refineEnabled"
    static let ollamaModel    = "koe.ollamaModel"
    static let ollamaBaseURL  = "koe.ollamaBaseURL"
    static let whisperModel   = "koe.whisperModel"
    static let hotkey         = "koe.hotkey"
    static let restoreClipboard = "koe.restoreClipboard"
    static let language       = "koe.language"
}

enum Settings {
    private static var d: UserDefaults { .standard }

    static func registerDefaults() {
        d.register(defaults: [
            SettingsKey.refineEnabled: true,
            SettingsKey.ollamaModel: "qwen2.5:3b",
            SettingsKey.ollamaBaseURL: "http://localhost:11434",
            SettingsKey.whisperModel: WhisperModelKind.small.rawValue,
            SettingsKey.hotkey: HotkeyKind.rightOption.rawValue,
            SettingsKey.restoreClipboard: true,
            SettingsKey.language: "ja"
        ])
    }

    static var refineEnabled: Bool { d.bool(forKey: SettingsKey.refineEnabled) }
    static var ollamaModel: String { d.string(forKey: SettingsKey.ollamaModel) ?? "qwen2.5:3b" }

    static var ollamaBaseURL: URL {
        // 環境変数による上書きを許可（テスト用）。
        if let env = ProcessInfo.processInfo.environment["KOE_OLLAMA_URL"], let u = URL(string: env) {
            return u
        }
        let s = d.string(forKey: SettingsKey.ollamaBaseURL) ?? "http://localhost:11434"
        return URL(string: s) ?? URL(string: "http://localhost:11434")!
    }

    static var whisperModel: WhisperModelKind {
        WhisperModelKind(rawValue: d.string(forKey: SettingsKey.whisperModel) ?? "") ?? .small
    }

    static var hotkey: HotkeyKind {
        HotkeyKind(rawValue: d.string(forKey: SettingsKey.hotkey) ?? "") ?? .rightOption
    }

    static var restoreClipboard: Bool { d.bool(forKey: SettingsKey.restoreClipboard) }
    static var language: String { d.string(forKey: SettingsKey.language) ?? "ja" }
}

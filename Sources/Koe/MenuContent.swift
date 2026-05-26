import SwiftUI
import AppKit

// メニューバーアイコンをクリックしたときに開くメニュー。
struct MenuContent: View {
    @EnvironmentObject var controller: AppController

    var body: some View {
        Text("Koe — \(controller.statusText)")

        if let p = controller.downloadProgress {
            Text(String(format: "モデルDL中… %d%%", Int(p * 100)))
        }

        if !controller.lastResult.isEmpty {
            Button("直前の結果をコピー") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(controller.lastResult, forType: .string)
            }
        }

        Divider()

        // 権限の状態（未許可は警告つきで表示）
        if !controller.micGranted {
            Button("⚠️ マイクを許可") { Permissions.openPrivacyPane(.microphone) }
        }
        if !controller.inputMonitoringGranted {
            Button("⚠️ 入力監視を許可（ホットキー）") { Permissions.openPrivacyPane(.inputMonitoring) }
        }
        if !controller.accessibilityGranted {
            Button("⚠️ アクセシビリティを許可（貼り付け）") { Permissions.openPrivacyPane(.accessibility) }
        }

        Button("ログ（記録）をFinderで開く") {
            NSWorkspace.shared.selectFile(SessionLogger.logFileURL.path,
                                          inFileViewerRootedAtPath: SessionLogger.logDirectory.path)
        }

        SettingsLink {
            Text("設定…")
        }
        .keyboardShortcut(",")

        Button("Koe について") {
            let alert = NSAlert()
            alert.messageText = "Koe"
            alert.informativeText = """
            LLM補完つきオフライン音声入力。
            \(Settings.hotkey.displayName) を押している間だけ録音し、離すと整形済みテキストを挿入します。
            音声認識: Whisper（ローカル） / 整形: Ollama（ローカル）
            """
            alert.runModal()
        }

        Divider()

        Button("終了") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

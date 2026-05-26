import SwiftUI
import AppKit

// アプリの起動点。メニューバーに常駐し、Dock にはアイコンを出さない（accessory）。
@main
struct KoeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
                .environmentObject(appDelegate.controller)
        } label: {
            // 状態に応じてアイコンを変える（待機=mic, 録音中=mic.fill の塗り, 処理中=波形）
            Image(systemName: appDelegate.controller.menuBarSymbol)
        }
        .menuBarExtraStyle(.menu)

        // 自前の enum Settings と区別するため SwiftUI.Settings を明示する。
        SwiftUI.Settings {
            SettingsView()
                .environmentObject(appDelegate.controller)
        }
    }
}

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // アプリ全体の制御役。各部品を束ねる。
    let controller = AppController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock にアイコンを出さず、メニューバー常駐にする。
        NSApp.setActivationPolicy(.accessory)
        Settings.registerDefaults()
        log("起動: メニューバー常駐 (accessory)")
        controller.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.shutdown()
    }
}

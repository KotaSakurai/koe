import AppKit
import SwiftUI

// 録音/処理中に画面下部へ浮かぶHUDパネルを管理する。
// 重要: フォーカスを奪わない（nonactivating）。奪うと貼り付け先のアプリが変わってしまう。
@MainActor
final class OverlayController {
    let model = OverlayModel()
    private var panel: NSPanel?

    private static let size = NSSize(width: 300, height: 64)

    func show(state: AppState) {
        ensurePanel()
        model.state = state
        position()
        panel?.orderFrontRegardless()
    }

    func update(state: AppState) {
        model.state = state
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func pushLevel(_ v: Float) {
        model.pushLevel(CGFloat(v))
    }

    func setElapsed(_ t: TimeInterval) {
        model.elapsed = t
    }

    // MARK: パネル生成・配置

    private func ensurePanel() {
        guard panel == nil else { return }
        let p = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isFloatingPanel = true
        p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = false
        p.ignoresMouseEvents = true     // クリックスルー（操作の邪魔をしない）
        p.hidesOnDeactivate = false

        let host = NSHostingView(rootView: OverlayView().environmentObject(model))
        host.frame = NSRect(origin: .zero, size: Self.size)
        host.autoresizingMask = [.width, .height]
        p.contentView = host
        panel = p
    }

    private func position() {
        guard let panel, let screen = NSScreen.main else { return }
        let area = screen.visibleFrame
        let x = area.midX - Self.size.width / 2
        let y = area.minY + 96     // 画面下部から少し上
        panel.setFrame(NSRect(x: x, y: y, width: Self.size.width, height: Self.size.height), display: true)
    }
}

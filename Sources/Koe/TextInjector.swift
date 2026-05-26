import AppKit
import CoreGraphics

// 整形済みテキストを、いま最前面のアプリのカーソル位置へ挿入する。
// 方式: クリップボードへコピー → ⌘V を合成送出。日本語 IME を経由しないため化けにくい。
// キー送出にはアクセシビリティ許可が必要。
enum TextInjector {

    enum InjectResult {
        case pasted              // ⌘V 送出まで完了
        case copiedOnly          // 権限不足等でクリップボードに置くだけ
    }

    @discardableResult
    @MainActor
    static func insert(_ text: String, restoreClipboard: Bool) -> InjectResult {
        guard !text.isEmpty else { return .copiedOnly }

        let pb = NSPasteboard.general
        let saved: String? = restoreClipboard ? pb.string(forType: .string) : nil

        pb.clearContents()
        pb.setString(text, forType: .string)

        guard Permissions.accessibilityGranted else {
            log("アクセシビリティ未許可のため貼り付けをスキップ。テキストはクリップボードにコピーしました")
            return .copiedOnly
        }

        sendCommandV()

        if restoreClipboard {
            // 貼り付けが処理されるのを待ってから元のクリップボードを復元する。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                pb.clearContents()
                if let saved { pb.setString(saved, forType: .string) }
            }
        }
        return .pasted
    }

    // ⌘V のキーダウン/アップを合成して送出する。
    private static func sendCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKeyCode: CGKeyCode = 0x09   // ANSI 'V'

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

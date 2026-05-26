import Foundation
import CoreGraphics
import Carbon.HIToolbox

// push-to-talk（押している間だけ録音）方式のホットキー検知。
// CGEvent タップで修飾キーの押下/解放を監視する。入力監視の許可が必要。
enum HotkeyKind: String, CaseIterable, Identifiable {
    case rightOption   // 右Option（既定）
    case fn            // fn（地球儀）キー

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .rightOption: return "右Option キー"
        case .fn:          return "fn（地球儀）キー"
        }
    }
    // 監視対象の keycode
    var keyCode: Int64 {
        switch self {
        case .rightOption: return Int64(kVK_RightOption)   // 0x3D
        case .fn:          return Int64(kVK_Function)       // 0x3F
        }
    }
    // 「押されている」と判定するためのフラグ
    var flag: CGEventFlags {
        switch self {
        case .rightOption: return .maskAlternate
        case .fn:          return .maskSecondaryFn
        }
    }
}

final class HotkeyManager {
    var onPressStart: (() -> Void)?
    var onPressEnd: (() -> Void)?

    private(set) var kind: HotkeyKind
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isPressing = false

    init(kind: HotkeyKind) {
        self.kind = kind
    }

    // 監視開始。許可が無ければ false を返す。
    @discardableResult
    func startMonitoring() -> Bool {
        stopMonitoring()

        let mask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,            // 観測のみ。キー入力は消費しない。
            eventsOfInterest: mask,
            callback: hotkeyTapCallback,
            userInfo: refcon
        ) else {
            log("ホットキー監視を開始できません（入力監視の許可が必要です）")
            return false
        }

        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        log("ホットキー監視開始: \(kind.displayName) 長押しで録音")
        return true
    }

    func stopMonitoring() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        tap = nil
        runLoopSource = nil
        isPressing = false
    }

    func updateKind(_ newKind: HotkeyKind) {
        kind = newKind
        if tap != nil { startMonitoring() }
    }

    // C コールバックから呼ばれる。修飾キーの状態遷移を判定する。
    // このコールバックはメインのランループ上で発火する（ソースをメインに登録済み）ため、
    // ディスパッチせずに直接コールバックを呼んでよい。
    fileprivate func handle(event: CGEvent) {
        let code = event.getIntegerValueField(.keyboardEventKeycode)
        guard code == kind.keyCode else { return }
        let down = event.flags.contains(kind.flag)
        if down && !isPressing {
            isPressing = true
            onPressStart?()
        } else if !down && isPressing {
            isPressing = false
            onPressEnd?()
        }
    }

    // タップが OS により無効化された場合（タイムアウト等）に再有効化する。
    fileprivate func reEnableIfNeeded() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
    }
}

// CGEvent タップの C コールバック。refcon 経由で HotkeyManager に戻す。
private func hotkeyTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()

    switch type {
    case .flagsChanged:
        manager.handle(event: event)
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        manager.reEnableIfNeeded()
    default:
        break
    }
    return Unmanaged.passUnretained(event)
}

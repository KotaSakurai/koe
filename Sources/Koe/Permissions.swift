import Foundation
import AVFoundation
import AppKit
import ApplicationServices
import IOKit.hid

// マイク・入力監視・アクセシビリティの許可を確認/要求するユーティリティ。
enum Permissions {

    // MARK: マイク

    static var microphoneGranted: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    static func requestMicrophone(_ completion: @escaping @Sendable (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }

    // MARK: 入力監視（CGEvent タップに必要）

    static var inputMonitoringGranted: Bool {
        IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
    }

    @discardableResult
    static func requestInputMonitoring() -> Bool {
        // 初回はシステムダイアログを出す。すでに判断済みなら状態を返す。
        if inputMonitoringGranted { return true }
        return IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }

    // MARK: アクセシビリティ（テキスト挿入＝キー送出に必要、M4 で使用）

    static var accessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func requestAccessibility(prompt: Bool) -> Bool {
        // kAXTrustedCheckOptionPrompt は安定した固定キー。グローバル変数参照を避けて文字列で指定する。
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    // MARK: 設定アプリの該当ペインを開く導線

    static func openPrivacyPane(_ section: PrivacySection) {
        if let url = URL(string: section.urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    enum PrivacySection {
        case microphone, inputMonitoring, accessibility
        var urlString: String {
            switch self {
            case .microphone:
                return "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
            case .inputMonitoring:
                return "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
            case .accessibility:
                return "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            }
        }
    }
}

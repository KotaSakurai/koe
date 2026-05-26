import Foundation

// 全体共通の簡易ログ。コンソール（make run のターミナル）に出す。
func log(_ message: String) {
    FileHandle.standardError.write("[Koe] \(message)\n".data(using: .utf8)!)
}

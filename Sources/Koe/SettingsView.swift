import SwiftUI

// 設定画面。@AppStorage で UserDefaults を直接束縛する（Settings 列挙と同じキー）。
struct SettingsView: View {
    @EnvironmentObject var controller: AppController

    @AppStorage(SettingsKey.whisperModel) private var whisperModel = WhisperModelKind.small.rawValue
    @AppStorage(SettingsKey.refineEnabled) private var refineEnabled = true
    @AppStorage(SettingsKey.ollamaModel) private var ollamaModel = "qwen2.5:3b"
    @AppStorage(SettingsKey.ollamaBaseURL) private var ollamaBaseURL = "http://localhost:11434"
    @AppStorage(SettingsKey.hotkey) private var hotkey = HotkeyKind.rightOption.rawValue
    @AppStorage(SettingsKey.restoreClipboard) private var restoreClipboard = true

    var body: some View {
        TabView {
            recognitionTab.tabItem { Label("認識", systemImage: "waveform") }
            refineTab.tabItem { Label("整形", systemImage: "sparkles") }
            generalTab.tabItem { Label("操作", systemImage: "keyboard") }
            permissionsTab.tabItem { Label("権限", systemImage: "lock.shield") }
        }
        .frame(width: 460, height: 360)
        .padding()
    }

    // MARK: 認識（Whisper）

    private var recognitionTab: some View {
        Form {
            Picker("Whisper モデル", selection: $whisperModel) {
                ForEach(WhisperModelKind.allCases) { m in
                    Text(m.displayName).tag(m.rawValue)
                }
            }
            .onChange(of: whisperModel) { _, _ in
                controller.ensureModelAvailable()
            }

            if let p = controller.downloadProgress {
                ProgressView(value: p) { Text("モデルをダウンロード中… \(Int(p * 100))%") }
            } else {
                HStack {
                    Image(systemName: controller.modelReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(controller.modelReady ? .green : .orange)
                    Text(controller.modelReady ? "モデルは利用可能です" : "モデル未取得（自動でダウンロードします）")
                    Spacer()
                    Button("再確認") { controller.ensureModelAvailable() }
                }
            }
            Text("モデルの変更はアプリの再起動後に反映されます。").font(.caption).foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: 整形（Ollama）

    private var refineTab: some View {
        Form {
            Toggle("LLM で整形・補正する（Ollama）", isOn: $refineEnabled)
            TextField("Ollama モデル名", text: $ollamaModel)
                .textFieldStyle(.roundedBorder)
            TextField("Ollama サーバ URL", text: $ollamaBaseURL)
                .textFieldStyle(.roundedBorder)
            Text("Ollama が未起動・接続失敗のときは、整形せず文字起こし結果をそのまま使います。")
                .font(.caption).foregroundStyle(.secondary)
            Text("導入例: brew install ollama → ollama serve → ollama pull \(ollamaModel)")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: 操作（ホットキー）

    private var generalTab: some View {
        Form {
            Picker("録音ホットキー（押している間だけ録音）", selection: $hotkey) {
                ForEach(HotkeyKind.allCases) { k in
                    Text(k.displayName).tag(k.rawValue)
                }
            }
            .onChange(of: hotkey) { _, _ in
                controller.reloadHotkey()
            }
            Toggle("貼り付け後にクリップボードを復元する", isOn: $restoreClipboard)
            Text("ホットキーを押している間に話し、離すと整形済みテキストが現在の入力欄に挿入されます。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: 権限

    private var permissionsTab: some View {
        Form {
            permissionRow("マイク", granted: controller.micGranted) {
                Permissions.openPrivacyPane(.microphone)
            }
            permissionRow("入力監視（ホットキー）", granted: controller.inputMonitoringGranted) {
                Permissions.openPrivacyPane(.inputMonitoring)
            }
            permissionRow("アクセシビリティ（貼り付け）", granted: controller.accessibilityGranted) {
                Permissions.openPrivacyPane(.accessibility)
            }
            Button("すべての許可をまとめて要求") { controller.requestAllPermissions() }
            Text("入力監視を新しく許可した場合は、アプリの再起動が必要なことがあります。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
    }

    private func permissionRow(_ title: String, granted: Bool, open: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(granted ? .green : .red)
            Text(title)
            Spacer()
            Button(granted ? "設定を開く" : "許可する") { open() }
        }
    }
}

import SwiftUI

// オーバーレイHUDの表示状態を保持する軽量モデル。
@MainActor
final class OverlayModel: ObservableObject {
    @Published var state: AppState = .recording
    @Published var levels: [CGFloat]      // 波形バーの履歴（左→右に流れる）
    @Published var elapsed: TimeInterval = 0

    static let barCount = 28

    init() {
        levels = Array(repeating: 0, count: OverlayModel.barCount)
    }

    func reset() {
        levels = Array(repeating: 0, count: OverlayModel.barCount)
        elapsed = 0
    }

    // 新しい音量を末尾に追加し、古いものを捨てる。
    func pushLevel(_ v: CGFloat) {
        levels.removeFirst()
        levels.append(max(0, min(1, v)))
    }
}

// 録音/処理中に画面下部へ浮かぶピル型のHUD。
struct OverlayView: View {
    @EnvironmentObject var model: OverlayModel

    var body: some View {
        HStack(spacing: 12) {
            switch model.state {
            case .recording:
                recordingContent
            case .transcribing:
                processingContent(symbol: "waveform", text: "文字起こし中…")
            case .refining:
                processingContent(symbol: "sparkles", text: "整形中…")
            case .error(let m):
                errorContent(m)
            case .idle:
                EmptyView()
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
        .background(
            Capsule(style: .continuous)
                .fill(.black.opacity(0.82))
                .overlay(Capsule(style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // 録音中: 脈動するマイク + 波形 + 経過時間
    private var recordingContent: some View {
        HStack(spacing: 12) {
            PulsingMic()
            Waveform(levels: model.levels)
                .frame(width: 150)
            Text(timeString(model.elapsed))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private func processingContent(symbol: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .symbolEffect(.pulse, options: .repeating)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
            ArcSpinner()
        }
    }

    private func errorContent(_ m: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
            Text(m).font(.system(size: 13)).foregroundStyle(.white).lineLimit(1)
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%01d:%02d", s / 60, s % 60)
    }
}

// 自前の回転アークスピナー（ProgressView と違いオフスクリーン描画でも正しく出る）。
private struct ArcSpinner: View {
    @State private var rotate = false
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.72)
            .stroke(
                AngularGradient(colors: [.white.opacity(0.15), .white], center: .center),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
            )
            .frame(width: 15, height: 15)
            .rotationEffect(.degrees(rotate ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    rotate = true
                }
            }
    }
}

// 赤く脈動する録音インジケータ付きマイク。
private struct PulsingMic: View {
    @State private var pulse = false
    var body: some View {
        Image(systemName: "mic.fill")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.red)
            .scaleEffect(pulse ? 1.15 : 0.9)
            .shadow(color: .red.opacity(0.7), radius: pulse ? 6 : 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

// 音量履歴を縦バーで描く波形。
private struct Waveform: View {
    let levels: [CGFloat]
    var body: some View {
        GeometryReader { geo in
            let count = max(levels.count, 1)
            let spacing: CGFloat = 3
            let barWidth = max(2, (geo.size.width - spacing * CGFloat(count - 1)) / CGFloat(count))
            HStack(alignment: .center, spacing: spacing) {
                ForEach(levels.indices, id: \.self) { i in
                    Capsule()
                        .fill(LinearGradient(colors: [.cyan, .blue],
                                             startPoint: .bottom, endPoint: .top))
                        .frame(width: barWidth,
                               height: max(3, levels[i] * geo.size.height))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .animation(.easeOut(duration: 0.08), value: levels)
        }
    }
}

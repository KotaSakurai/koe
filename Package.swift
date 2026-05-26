// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Koe",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        // whisper.cpp の C ヘッダを公開するモジュール。実体は Vendor/whisper/lib の静的ライブラリ。
        .target(
            name: "CWhisper",
            path: "Sources/CWhisper"
        ),
        .executableTarget(
            name: "Koe",
            dependencies: ["CWhisper"],
            path: "Sources/Koe",
            linkerSettings: [
                // scripts/build-whisper.sh が配置する静的ライブラリをリンクする。
                .unsafeFlags([
                    "-L", "Vendor/whisper/lib",
                    "-lwhisper",
                    "-lggml",
                    "-lggml-cpu",
                    "-lggml-metal",
                    "-lggml-base",
                    "-lc++"
                ]),
                .linkedFramework("Metal"),
                .linkedFramework("Accelerate"),
                .linkedFramework("Foundation")
            ]
        )
    ]
)

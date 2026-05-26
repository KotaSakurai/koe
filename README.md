# Koe — LLM補完つきオフライン音声入力（macOS）

「Typeless」のような、どこでも使える音声入力ツール。グローバルなホットキーを押している間だけ録音し、離すと **ローカルの Whisper** で文字起こし、**ローカルの Ollama（LLM）** で誤認識補正・句読点付与・整形を行い、整形済みテキストを **いま入力中のアプリのカーソル位置に自動挿入** します。音声・テキストは一切外部送信しません（完全オフライン。整形は Ollama 未導入時は自動でスキップ）。

- 音声認識: whisper.cpp（v1.7.6 を静的リンク、Apple Silicon / Metal）
- 整形: Ollama（`http://localhost:11434`、任意・推奨）
- 形態: メニューバー常駐 + push-to-talk（既定は右Option 長押し）

## 必要環境

- Apple Silicon Mac（arm64）、macOS 14 以降
- Xcode（Swift 6 系）

## ビルド

初回のみ whisper.cpp の静的ライブラリを用意します（cmake は `./scripts/build-whisper.sh` が `.tools/` のローカル版を使用、ソースは `third_party/whisper.cpp`）。

    cd koe
    ./scripts/build-whisper.sh     # 数分。Vendor/whisper/lib に .a を生成
    make                           # build/Koe.app を生成（ad-hoc 署名）
    open build/Koe.app             # 起動（ログを見るなら make run）

## セットアップ

1. メニューバーのアイコン → 各権限を許可：
   - マイク（録音）
   - 入力監視（ホットキー検知）※許可後はアプリを再起動
   - アクセシビリティ（⌘V 貼り付け）
2. Whisper モデルは初回起動時に `ggml-small.bin`（約466MB）を自動ダウンロード（`~/Library/Application Support/Koe/models/`）。手動なら `./scripts/download-model.sh small`。
3. 整形（推奨）：Ollama を導入・起動し、モデルを取得。

       brew install ollama
       ollama serve            # 別ターミナルで常駐
       ollama pull qwen2.5:3b  # 設定の「整形」タブのモデル名と合わせる

## 使い方

テキスト入力欄にカーソルを置き、**右Option を押しながら話して離す**。数秒後、整形済みテキストが挿入されます。設定（メニュー → 設定…）でモデル・ホットキー・整形ON/OFF・Ollama 接続先を変更できます。

## 動作の仕組み

`HotkeyManager`(CGEvent) → `AudioRecorder`(16kHz/mono) → `WhisperTranscriber`(whisper.cpp) → `OllamaClient`(/api/chat) → `TextInjector`(クリップボード＋⌘V)。詳細と設計判断は [`plans/2026-05-25-voice-input-mac-app/ExecPlan.md`](plans/2026-05-25-voice-input-mac-app/ExecPlan.md) を参照。

## 自己テスト（headless）

    KOE_SELFTEST=1 KOE_SELFTEST_EXIT=1 ./build/Koe.app/Contents/MacOS/Koe          # 3秒録音→サンプル数
    say -v Kyoko -o /tmp/t.aiff "今日はいい天気です"
    KOE_TRANSCRIBE_FILE=/tmp/t.aiff KOE_SELFTEST_EXIT=1 ./build/Koe.app/Contents/MacOS/Koe  # 文字起こし＋整形
    KOE_INSERT_TEST="テスト" KOE_SELFTEST_EXIT=1 ./build/Koe.app/Contents/MacOS/Koe          # クリップボード挿入

## コントリビュート

不具合報告・機能提案・プルリクエストを歓迎します。大きな変更を行う場合は、先に Issue で相談いただけると円滑です。設計の背景は `plans/2026-05-25-voice-input-mac-app/ExecPlan.md` を参照してください。

## ライセンス

[MIT License](LICENSE) で配布します。Copyright (c) 2026 kazumalab。

## 謝辞・サードパーティ

本アプリは [whisper.cpp](https://github.com/ggml-org/whisper.cpp)（MIT）と [ggml](https://github.com/ggml-org/ggml)（MIT）を静的リンクし、ローカル整形に [Ollama](https://github.com/ollama/ollama)（MIT、任意・実行時）を利用します。Whisper のモデル重みは OpenAI 由来（MIT）です。各依存の詳細は [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) を参照してください。

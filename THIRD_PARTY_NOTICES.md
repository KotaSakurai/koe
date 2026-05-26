# サードパーティのお知らせ（Third-Party Notices）

Koe は以下のオープンソース／第三者の成果物を利用しています。各ソフトウェアの著作権は各権利者に帰属します。

## ビルド時に組み込む（静的リンク）

- **whisper.cpp** — MIT License — https://github.com/ggml-org/whisper.cpp
  本リポジトリでは `scripts/build-whisper.sh` がタグ `v1.7.6` を取得し、静的ライブラリ
  （`libwhisper.a` など）として `Koe` 実行ファイルへリンクします。
- **ggml** — MIT License — https://github.com/ggml-org/ggml
  whisper.cpp に同梱される ggml（CPU / Metal バックエンドを含む）を利用します。

## 実行時に必要（同梱しません。利用者が各自取得）

- **Whisper ggml モデル**（例: `ggml-large-v3-turbo.bin`, `ggml-small.bin`）
  OpenAI Whisper 由来。モデル重みは MIT License。配布元: Hugging Face
  `https://huggingface.co/ggerganov/whisper.cpp`。初回起動時にアプリが自動ダウンロードします。
- **Ollama** — MIT License — https://github.com/ollama/ollama
  ローカルLLMの実行に使用（任意）。本アプリには同梱せず、HTTP API 経由で接続します。
- **Ollama 上で動かす LLM モデル**（例: `qwen2.5:3b` ほか）
  各モデルには固有のライセンスがあります（Qwen2.5 等）。利用者が `ollama pull` で取得し、
  各モデルのライセンス条件に従ってください。

## ビルドツール（成果物には含まれません）

- **CMake** — BSD 3-Clause License — https://cmake.org/
  whisper.cpp の静的ライブラリ生成にのみ使用します。

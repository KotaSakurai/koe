#!/bin/bash
# Whisper の ggml モデルを ~/Library/Application Support/Koe/models/ に手動でダウンロードする。
# 通常はアプリ初回起動時に自動DLされるため必須ではない。
# 使い方: ./scripts/download-model.sh [base|small|medium]   (既定: small)
set -euo pipefail

KIND="${1:-small}"
FILE="ggml-${KIND}.bin"
URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${FILE}"
DEST_DIR="$HOME/Library/Application Support/Koe/models"

mkdir -p "$DEST_DIR"
if [ -f "$DEST_DIR/$FILE" ]; then
    echo "既に存在します: $DEST_DIR/$FILE"
    exit 0
fi
echo "ダウンロード中: $FILE"
curl -L -o "$DEST_DIR/$FILE" "$URL"
echo "完了: $DEST_DIR/$FILE"

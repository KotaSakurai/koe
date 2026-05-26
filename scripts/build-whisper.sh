#!/bin/bash
# whisper.cpp を静的ライブラリ（arm64・Metal シェーダ埋め込み）としてビルドし、
# Koe の SwiftPM ターゲットがリンクできるよう成果物を配置する。
# 前提: koe/.tools/cmake-*/CMake.app に cmake、koe/third_party/whisper.cpp にソース。
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"          # koe/
# cmake は環境変数 CMAKE で上書き可能（CI では brew の cmake を使う）。
# 未指定ならローカル展開した .tools/cmake-* を使う。
CMAKE="${CMAKE:-$(echo "$HERE"/.tools/cmake-*/CMake.app/Contents/bin/cmake)}"
WHISPER_TAG="${WHISPER_TAG:-v1.7.6}"
WD="$HERE/third_party/whisper.cpp"
BUILD="$WD/build-koe"

if ! command -v "$CMAKE" >/dev/null 2>&1 && [ ! -x "$CMAKE" ]; then
    echo "cmake が見つかりません: $CMAKE（CMAKE 環境変数で指定可）" >&2; exit 1
fi
# whisper.cpp が無ければ指定タグを浅くクローンする（CI・新規クローン向け）。
if [ ! -d "$WD" ]; then
    echo "[build-whisper] whisper.cpp ($WHISPER_TAG) を取得..."
    git clone --depth 1 --branch "$WHISPER_TAG" https://github.com/ggml-org/whisper.cpp "$WD"
fi

echo "[build-whisper] cmake 構成..."
"$CMAKE" -B "$BUILD" -S "$WD" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DGGML_METAL=ON \
    -DGGML_METAL_EMBED_LIBRARY=ON \
    -DGGML_BLAS=OFF \
    -DGGML_OPENMP=OFF \
    -DGGML_NATIVE=OFF \
    -DWHISPER_BUILD_EXAMPLES=OFF \
    -DWHISPER_BUILD_TESTS=OFF \
    -DWHISPER_BUILD_SERVER=OFF \
    -DWHISPER_COREML=OFF \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0

echo "[build-whisper] ビルド..."
"$CMAKE" --build "$BUILD" --config Release -j

echo "[build-whisper] 成果物を配置..."
LIBDEST="$HERE/Vendor/whisper/lib"
INCDEST="$HERE/Sources/CWhisper/include"
mkdir -p "$LIBDEST" "$INCDEST"
rm -f "$LIBDEST"/*.a

# 生成された静的ライブラリを収集（同名は上書き）
find "$BUILD" -name "*.a" -print0 | while IFS= read -r -d '' f; do
    cp "$f" "$LIBDEST/"
done

# ヘッダを CWhisper モジュールの include へ複製
cp "$WD/include/whisper.h" "$INCDEST/"
cp "$WD/ggml/include/"*.h "$INCDEST/"

echo "[build-whisper] 配置済みライブラリ:"
ls -1 "$LIBDEST"
echo "[build-whisper] 完了"

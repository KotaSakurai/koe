APP        := Koe
CONFIG     := release
BIN        := .build/$(CONFIG)/$(APP)
BUNDLE     := build/$(APP).app
CONTENTS   := $(BUNDLE)/Contents
ENTITLE    := Resources/Koe.entitlements
BUNDLE_ID  := com.kazumalab.koe
# ad-hoc 署名の既定 Designated Requirement は cdhash（バイナリのハッシュ）になり、
# 再ビルドのたびに値が変わるため、入力監視・アクセシビリティの権限が毎回リセットされる。
# Bundle ID ベースの安定した要件を埋め込み、再ビルドしても TCC が同一アプリと認識し続けるようにする。
DESIGNATED := =designated => identifier "$(BUNDLE_ID)"

.PHONY: all build app sign run clean

all: app

build:
	@# 静的ライブラリ(.a)を差し替えても SwiftPM は再リンクを省略するため、
	@# 実行ファイルを削除して必ず最新の Vendor/whisper/lib を取り込ませる。
	@rm -f $(BIN)
	swift build -c $(CONFIG)

# .app バンドルを組み立てて ad-hoc 署名する
app: build
	@rm -rf $(BUNDLE)
	@mkdir -p $(CONTENTS)/MacOS $(CONTENTS)/Resources
	cp $(BIN) $(CONTENTS)/MacOS/$(APP)
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	@# whisper.cpp 等が生成するリソースバンドル(.bundle)があれば同梱する
	@if ls .build/$(CONFIG)/*.bundle >/dev/null 2>&1; then \
		cp -R .build/$(CONFIG)/*.bundle $(CONTENTS)/Resources/ ; \
		echo "リソースバンドルを同梱しました" ; \
	fi
	@$(MAKE) sign
	@echo "生成: $(BUNDLE)"

# ad-hoc 署名（自己署名）。entitlements があれば付与する。
sign:
	@if [ -f $(ENTITLE) ]; then \
		codesign --force --sign - --identifier $(BUNDLE_ID) --requirements '$(DESIGNATED)' --entitlements $(ENTITLE) --options runtime $(BUNDLE) ; \
	else \
		codesign --force --sign - --identifier $(BUNDLE_ID) --requirements '$(DESIGNATED)' $(BUNDLE) ; \
	fi

# 実行ファイルを直接起動してログをターミナルに表示する
run: app
	$(CONTENTS)/MacOS/$(APP)

clean:
	rm -rf build .build

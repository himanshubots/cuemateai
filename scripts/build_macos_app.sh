#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="Cuemate.app"
APP_DIR="$DIST_DIR/$APP_NAME"
ICONSET_DIR="$ROOT_DIR/Packaging/Cuemate.iconset"
ICNS_PATH="$ROOT_DIR/Packaging/Cuemate.icns"
CACHE_HOME="$ROOT_DIR/.build/toolchain-home"
CLANG_CACHE="$ROOT_DIR/.build/clang-module-cache"
SWIFT_CACHE="$ROOT_DIR/.build/swift-module-cache"

if [ -d /Applications/Xcode.app/Contents/Developer ]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

mkdir -p "$DIST_DIR"
mkdir -p "$CACHE_HOME" "$CLANG_CACHE" "$SWIFT_CACHE"

export HOME="$CACHE_HOME"
export CLANG_MODULE_CACHE_PATH="$CLANG_CACHE"
export SWIFT_MODULECACHE_PATH="$SWIFT_CACHE"

swift build -c release --product cuemate

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

swift "$ROOT_DIR/scripts/generate_app_icon.swift" "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"

cp "$ROOT_DIR/.build/release/cuemate" "$APP_DIR/Contents/MacOS/Cuemate"
chmod +x "$APP_DIR/Contents/MacOS/Cuemate"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ICNS_PATH" "$APP_DIR/Contents/Resources/Cuemate.icns"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true
fi

echo "Built app bundle at: $APP_DIR"

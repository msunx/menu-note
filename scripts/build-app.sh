#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
MODULE_CACHE="$BUILD_DIR/module-cache"
DIST_DIR="$PROJECT_DIR/dist"
APP_PATH="$DIST_DIR/Menu Note.app"
EXPECTED_APP_PATH="$PROJECT_DIR/dist/Menu Note.app"
CONTENTS_PATH="$APP_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"
RESOURCES_PATH="$CONTENTS_PATH/Resources"
ICONSET_PATH="$BUILD_DIR/AppIcon.iconset"
ICON_PATH="$RESOURCES_PATH/AppIcon.icns"
ICON_GENERATOR="$BUILD_DIR/generate-icon"
TARGET_ARCH="${ARCH:-$(uname -m)}"

if [[ "$APP_PATH" != "$EXPECTED_APP_PATH" ]]; then
    print -u2 "拒绝清理意外路径：$APP_PATH"
    exit 1
fi

if [[ ! -x /usr/bin/clang ]]; then
    print -u2 "未找到 Apple Clang。请运行：xcode-select --install"
    exit 1
fi

/bin/rm -rf "$APP_PATH" "$ICONSET_PATH"
/bin/mkdir -p "$MACOS_PATH" "$RESOURCES_PATH/Web" "$MODULE_CACHE" "$ICONSET_PATH"

/usr/bin/clang \
    -fobjc-arc \
    -fmodules \
    -fmodules-cache-path="$MODULE_CACHE" \
    -arch "$TARGET_ARCH" \
    -mmacosx-version-min=14.0 \
    -Os \
    -DNDEBUG \
    -Wall \
    -Wextra \
    -I "$PROJECT_DIR/Sources/MenuNote" \
    "$PROJECT_DIR"/Sources/MenuNote/*.m \
    -framework Cocoa \
    -framework WebKit \
    -o "$MACOS_PATH/MenuNote"

/bin/cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_PATH/Info.plist"
/bin/cp "$PROJECT_DIR"/Resources/Web/* "$RESOURCES_PATH/Web/"

/usr/bin/clang \
    -fobjc-arc \
    -fmodules \
    -fmodules-cache-path="$MODULE_CACHE" \
    -arch "$TARGET_ARCH" \
    -mmacosx-version-min=14.0 \
    "$PROJECT_DIR/scripts/generate_icon.m" \
    -framework Cocoa \
    -o "$ICON_GENERATOR"

"$ICON_GENERATOR" "$ICONSET_PATH" "$ICON_PATH"

/usr/bin/codesign --force --deep --sign - "$APP_PATH"
/usr/bin/codesign --verify --deep --strict "$APP_PATH"

print "已生成：$APP_PATH"
print "运行：open '$APP_PATH'"


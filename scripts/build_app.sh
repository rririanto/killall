#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Building QuiteAll (Release)..."
cd "$PROJECT_DIR"
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/QuiteAll"
APP_DIR="$PROJECT_DIR/QuiteAll.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Packaging QuiteAll.app..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp "$BIN_PATH" "$MACOS_DIR/QuiteAll"
chmod +x "$MACOS_DIR/QuiteAll"

# Copy Info.plist
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy Icon
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Copy Sounds
if [ -d "$PROJECT_DIR/Resources/Sounds" ]; then
    cp -R "$PROJECT_DIR/Resources/Sounds/"* "$RESOURCES_DIR/"
fi

# Ad-hoc codesign
echo "🔏 Code-signing QuiteAll.app..."
codesign --force --deep --sign - "$APP_DIR"

echo "✅ Build complete: $APP_DIR"

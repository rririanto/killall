#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION=$(git describe --tags --exact-match 2>/dev/null || git describe --tags --abbrev=0 2>/dev/null || echo "v2.0.0")
ARCH_TARGET="universal"
CREATE_ZIPS=false

for arg in "$@"; do
    case "$arg" in
        --universal)
            ARCH_TARGET="universal"
            ;;
        --arm64)
            ARCH_TARGET="arm64"
            ;;
        --intel|--x86_64)
            ARCH_TARGET="x86_64"
            ;;
        --zip)
            CREATE_ZIPS=true
            ;;
        --all)
            ARCH_TARGET="all"
            CREATE_ZIPS=true
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [--universal | --arm64 | --intel | --all] [--zip]"
            exit 1
            ;;
    esac
done

cd "$PROJECT_DIR"

build_arch() {
    local arch="$1"
    echo "🔨 Compiling KillAll for $arch..."
    swift build -c release --triple "${arch}-apple-macosx"
}

package_bundle() {
    local bin_source="$1"
    local dest_dir="$2"
    local app_dir="$dest_dir/KillAll.app"
    local contents_dir="$app_dir/Contents"
    local macos_dir="$contents_dir/MacOS"
    local resources_dir="$contents_dir/Resources"

    rm -rf "$app_dir"
    mkdir -p "$macos_dir"
    mkdir -p "$resources_dir"

    cp "$bin_source" "$macos_dir/KillAll"
    chmod +x "$macos_dir/KillAll"

    cp "$PROJECT_DIR/Resources/Info.plist" "$contents_dir/Info.plist"

    if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
        cp "$PROJECT_DIR/Resources/AppIcon.icns" "$resources_dir/AppIcon.icns"
    fi

    if [ -d "$PROJECT_DIR/Resources/Sounds" ]; then
        cp -R "$PROJECT_DIR/Resources/Sounds/"* "$resources_dir/"
    fi

    echo "🔏 Code-signing $app_dir..."
    codesign --force --deep --sign - "$app_dir"
}

build_universal_bin() {
    build_arch "arm64"
    build_arch "x86_64"

    mkdir -p "$PROJECT_DIR/.build/universal"
    lipo -create \
        "$PROJECT_DIR/.build/arm64-apple-macosx/release/KillAll" \
        "$PROJECT_DIR/.build/x86_64-apple-macosx/release/KillAll" \
        -output "$PROJECT_DIR/.build/universal/KillAll"
}

if [ "$ARCH_TARGET" = "universal" ]; then
    build_universal_bin
    package_bundle "$PROJECT_DIR/.build/universal/KillAll" "$PROJECT_DIR"
    echo "✅ Universal KillAll.app built successfully at: $PROJECT_DIR/KillAll.app"
    file "$PROJECT_DIR/KillAll.app/Contents/MacOS/KillAll"

    if [ "$CREATE_ZIPS" = true ]; then
        ZIP_NAME="KillAll-${VERSION}-Universal.zip"
        ditto -c -k --sequesterRsrc --keepParent "$PROJECT_DIR/KillAll.app" "$PROJECT_DIR/$ZIP_NAME"
        echo "📦 Packaged: $PROJECT_DIR/$ZIP_NAME"
    fi

elif [ "$ARCH_TARGET" = "arm64" ]; then
    build_arch "arm64"
    package_bundle "$PROJECT_DIR/.build/arm64-apple-macosx/release/KillAll" "$PROJECT_DIR"
    echo "✅ Apple Silicon (arm64) KillAll.app built successfully at: $PROJECT_DIR/KillAll.app"
    file "$PROJECT_DIR/KillAll.app/Contents/MacOS/KillAll"

    if [ "$CREATE_ZIPS" = true ]; then
        ZIP_NAME="KillAll-${VERSION}-AppleSilicon-arm64.zip"
        ditto -c -k --sequesterRsrc --keepParent "$PROJECT_DIR/KillAll.app" "$PROJECT_DIR/$ZIP_NAME"
        echo "📦 Packaged: $PROJECT_DIR/$ZIP_NAME"
    fi

elif [ "$ARCH_TARGET" = "x86_64" ]; then
    build_arch "x86_64"
    package_bundle "$PROJECT_DIR/.build/x86_64-apple-macosx/release/KillAll" "$PROJECT_DIR"
    echo "✅ Intel (x86_64) KillAll.app built successfully at: $PROJECT_DIR/KillAll.app"
    file "$PROJECT_DIR/KillAll.app/Contents/MacOS/KillAll"

    if [ "$CREATE_ZIPS" = true ]; then
        ZIP_NAME="KillAll-${VERSION}-Intel-x86_64.zip"
        ditto -c -k --sequesterRsrc --keepParent "$PROJECT_DIR/KillAll.app" "$PROJECT_DIR/$ZIP_NAME"
        echo "📦 Packaged: $PROJECT_DIR/$ZIP_NAME"
    fi

elif [ "$ARCH_TARGET" = "all" ]; then
    echo "🚀 Building All Target Architectures (Universal, Apple Silicon, Intel)..."
    build_universal_bin

    # 1. Universal
    mkdir -p "$PROJECT_DIR/dist/universal"
    package_bundle "$PROJECT_DIR/.build/universal/KillAll" "$PROJECT_DIR/dist/universal"
    ditto -c -k --sequesterRsrc --keepParent "$PROJECT_DIR/dist/universal/KillAll.app" "$PROJECT_DIR/KillAll-${VERSION}-Universal.zip"
    echo "📦 Packaged: KillAll-${VERSION}-Universal.zip"

    # 2. Apple Silicon (arm64)
    mkdir -p "$PROJECT_DIR/dist/arm64"
    package_bundle "$PROJECT_DIR/.build/arm64-apple-macosx/release/KillAll" "$PROJECT_DIR/dist/arm64"
    ditto -c -k --sequesterRsrc --keepParent "$PROJECT_DIR/dist/arm64/KillAll.app" "$PROJECT_DIR/KillAll-${VERSION}-AppleSilicon-arm64.zip"
    echo "📦 Packaged: KillAll-${VERSION}-AppleSilicon-arm64.zip"

    # 3. Intel (x86_64)
    mkdir -p "$PROJECT_DIR/dist/x86_64"
    package_bundle "$PROJECT_DIR/.build/x86_64-apple-macosx/release/KillAll" "$PROJECT_DIR/dist/x86_64"
    ditto -c -k --sequesterRsrc --keepParent "$PROJECT_DIR/dist/x86_64/KillAll.app" "$PROJECT_DIR/KillAll-${VERSION}-Intel-x86_64.zip"
    echo "📦 Packaged: KillAll-${VERSION}-Intel-x86_64.zip"

    # Default root KillAll.app is Universal
    cp -R "$PROJECT_DIR/dist/universal/KillAll.app" "$PROJECT_DIR/KillAll.app"
    rm -rf "$PROJECT_DIR/dist"

    echo "🎉 All packages generated successfully!"
fi

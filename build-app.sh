#!/bin/bash
set -e

APP_NAME="ClaudeCodeUsage"
BUNDLE_DIR="$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building arm64 binary..."

swift build -c release --arch arm64 2>&1

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp .build/arm64-apple-macosx/release/$APP_NAME "$MACOS_DIR/$APP_NAME"
cp ClaudeCodeUsage/Sources/App/Info.plist "$CONTENTS_DIR/Info.plist"
cp ClaudeCodeUsage/Sources/Resources/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"

echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

file "$MACOS_DIR/$APP_NAME"
echo ""
echo "Built $BUNDLE_DIR successfully"
echo "Run: open $BUNDLE_DIR"

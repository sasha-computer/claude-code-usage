#!/bin/bash
set -e

APP_NAME="CCUsage"
BUNDLE_DIR="$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building universal binary (arm64 + x86_64)..."

swift build -c release --arch arm64 --arch x86_64 2>&1

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp .build/apple/Products/Release/$APP_NAME "$MACOS_DIR/$APP_NAME"
cp CCUsage/Sources/App/Info.plist "$CONTENTS_DIR/Info.plist"

echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

file "$MACOS_DIR/$APP_NAME"
echo ""
echo "Built $BUNDLE_DIR successfully"
echo "Run: open $BUNDLE_DIR"

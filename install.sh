#!/bin/bash
set -e

REPO="jaehyunjang/ccusage"
APP_NAME="CCUsage"
INSTALL_DIR="/Applications"
TMP_DIR=$(mktemp -d)

echo "Installing $APP_NAME..."

if [ -n "$1" ]; then
    VERSION="$1"
else
    VERSION=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | head -1 | cut -d'"' -f4)
fi

if [ -z "$VERSION" ]; then
    echo "Error: Could not determine latest version"
    exit 1
fi

echo "Version: $VERSION"

DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/$APP_NAME.zip"
echo "Downloading from $DOWNLOAD_URL..."

curl -sL "$DOWNLOAD_URL" -o "$TMP_DIR/$APP_NAME.zip"

echo "Extracting..."
cd "$TMP_DIR"
unzip -q "$APP_NAME.zip"

if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo "Removing previous installation..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

echo "Installing to $INSTALL_DIR..."
mv "$APP_NAME.app" "$INSTALL_DIR/"

rm -rf "$TMP_DIR"

echo ""
echo "Installed $APP_NAME $VERSION to $INSTALL_DIR/$APP_NAME.app"
echo ""
echo "First launch: Right-click the app > Open (required once for unsigned apps)"
echo ""

read -p "Launch now? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    open "$INSTALL_DIR/$APP_NAME.app"
fi

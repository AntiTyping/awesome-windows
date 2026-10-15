#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Awesome Windows"
BUNDLE_ID="com.artcraft.awesome-windows"
BUILD_DIR="$PROJECT_DIR/.build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

echo "Building..."
cd "$PROJECT_DIR"
swift build -c debug

echo "Assembling app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/debug/AwesomeWindows" "$APP_DIR/Contents/MacOS/AwesomeWindows"
cp "$PROJECT_DIR/Sources/Info.plist" "$APP_DIR/Contents/Info.plist"

codesign --force --sign - --identifier "$BUNDLE_ID" "$APP_DIR"

echo "Built: $APP_DIR"
echo ""
echo "Run with:"
echo "  open \"$APP_DIR\""

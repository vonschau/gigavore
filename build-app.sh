#!/bin/bash
# Builds Gigavore.app into the build/ directory.
# By default builds a universal binary (arm64 + x86_64); pass --native to
# build only for the current architecture (faster for development).
set -euo pipefail
cd "$(dirname "$0")"

if [[ "${1:-}" == "--native" ]]; then
    swift build -c release
    BINARY=".build/release/Gigavore"
else
    swift build -c release --arch arm64 --arch x86_64
    BINARY=".build/apple/Products/Release/Gigavore"
fi

APP="build/Gigavore.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINARY" "$APP/Contents/MacOS/Gigavore"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc signature (sufficient for running locally).
codesign --force --sign - "$APP"

echo "Done: $APP"
lipo -archs "$APP/Contents/MacOS/Gigavore" 2>/dev/null || true
echo "Run with: open $APP"

#!/bin/bash
# Builds Gigavore.app into the build/ directory.
#
# Usage:
#   ./build-app.sh                  universal build, ad-hoc signature
#   ./build-app.sh --native         current-arch build (faster for development)
#   SIGN_IDENTITY="Developer ID Application: ..." ./build-app.sh
#                                   universal build signed with hardened runtime
#                                   (required for notarization)
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

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
    codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp "$APP"
    echo "Signed with: $SIGN_IDENTITY"
else
    # Ad-hoc signature (sufficient for running locally).
    codesign --force --sign - "$APP"
fi

echo "Done: $APP"
lipo -archs "$APP/Contents/MacOS/Gigavore" 2>/dev/null || true
echo "Run with: open $APP"

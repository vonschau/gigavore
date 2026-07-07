#!/bin/bash
# Builds Gigavore.app into the build/ directory.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="build/Gigavore.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Gigavore "$APP/Contents/MacOS/Gigavore"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc signature (sufficient for running locally).
codesign --force --sign - "$APP"

echo "Done: $APP"
echo "Run with: open $APP"

#!/bin/bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$REPO_DIR/build/UITest.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp -R "$REPO_DIR/Resources/en.lproj" "$REPO_DIR/Resources/es.lproj" "$APP/Contents/Resources/"
xcrun swiftc -D UI_TESTING "$REPO_DIR/Sources/Localization.swift" \
  "$REPO_DIR/Sources/MonitorCore.swift" "$REPO_DIR/Sources/main.swift" \
  -o "$APP/Contents/MacOS/UITest" -framework AppKit -framework CoreGraphics -framework ColorSync
"$APP/Contents/MacOS/UITest"

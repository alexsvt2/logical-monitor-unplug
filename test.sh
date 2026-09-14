#!/bin/bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$REPO_DIR/build"
xcrun swiftc "$REPO_DIR/Sources/Localization.swift" "$REPO_DIR/Sources/MonitorCore.swift" "$REPO_DIR/Tests/main.swift" -o "$REPO_DIR/build/PolicyTests" -framework AppKit -framework CoreGraphics -framework ColorSync
"$REPO_DIR/build/PolicyTests" "$REPO_DIR/Resources"
plutil -lint "$REPO_DIR/Resources/en.lproj/Localizable.strings" "$REPO_DIR/Resources/es.lproj/Localizable.strings"
bash -n "$REPO_DIR/build.sh" "$REPO_DIR/install.sh" "$REPO_DIR/test-ui.sh" "$REPO_DIR/bin/toggle_monitor.sh"

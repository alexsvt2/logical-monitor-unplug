#!/bin/bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$REPO_DIR/build"
xcrun swiftc "$REPO_DIR/Sources/MonitorCore.swift" "$REPO_DIR/Tests/main.swift" -o "$REPO_DIR/build/PolicyTests" -framework AppKit -framework CoreGraphics -framework ColorSync
"$REPO_DIR/build/PolicyTests"
bash -n "$REPO_DIR/build.sh" "$REPO_DIR/install.sh" "$REPO_DIR/bin/toggle_monitor.sh"

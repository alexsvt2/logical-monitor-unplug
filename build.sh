#!/bin/bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$REPO_DIR/dist/LogicalUnplug.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$REPO_DIR/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp -R "$REPO_DIR/Resources/en.lproj" "$REPO_DIR/Resources/es.lproj" "$APP/Contents/Resources/"
xcrun swiftc -O -target "$(uname -m)-apple-macosx13.0" "$REPO_DIR/Sources/Localization.swift" "$REPO_DIR/Sources/MonitorCore.swift" "$REPO_DIR/Sources/main.swift" -o "$APP/Contents/MacOS/LogicalUnplug" -framework AppKit -framework CoreGraphics -framework ColorSync
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.alexsvt.logical-monitor-unplug</string>
<key>CFBundleName</key><string>Logical Unplug</string>
<key>CFBundleDisplayName</key><string>Logical Unplug</string>
<key>CFBundleExecutable</key><string>LogicalUnplug</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.3.0</string>
<key>CFBundleVersion</key><string>3</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleLocalizations</key><array><string>en</string><string>es</string></array>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
printf 'App creada: %s\n' "$APP"

#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP="${APP_OUTPUT_DIR:-dist}/NextReset@TokenPark.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/TokenPark" "$APP/Contents/MacOS/TokenPark"
cp assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp assets/nextreset-logo.png "$APP/Contents/Resources/NextResetLogo.png"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>app.tokenpark.menubar</string>
<key>CFBundleName</key><string>NextReset@TokenPark</string>
<key>CFBundleDisplayName</key><string>NextReset@TokenPark</string>
<key>CFBundleExecutable</key><string>TokenPark</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.2.1</string>
<key>CFBundleVersion</key><string>3</string>
<key>LSUIElement</key><true/>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>CFBundleDevelopmentRegion</key><string>en</string>
</dict></plist>
PLIST
if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP/Contents/MacOS/TokenPark"
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP"
else
  codesign --force --sign - "$APP"
fi
codesign --verify --deep --strict "$APP"
printf '\nBuilt %s\n' "$APP"

#!/usr/bin/env bash
# Bundle the release binary into MenuBarNotes.app and zip it.
set -euo pipefail

BIN="${1:?usage: package-app.sh <path-to-binary> [out.zip]}"
OUT="${2:-MenuBarNotes.zip}"
APP="MenuBarNotes.app"

rm -rf "$APP" "$OUT"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/MenuBarNotes"
chmod +x "$APP/Contents/MacOS/MenuBarNotes"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MenuBarNotes</string>
    <key>CFBundleIdentifier</key>
    <string>com.karkarbinksjar.MenuBarNotes</string>
    <key>CFBundleName</key>
    <string>MenuBarNotes</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

codesign --force -s - "$APP"
zip -qry "$OUT" "$APP"
echo "Built $OUT"

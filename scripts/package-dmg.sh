#!/usr/bin/env bash
# Wrap MenuBarNotes.app in a compressed disk image for distribution.
set -euo pipefail

APP="${1:-MenuBarNotes.app}"
OUT="${2:-MenuBarNotes.dmg}"

if [[ ! -d "$APP" ]]; then
    echo "error: $APP not found (run scripts/package-app.sh first)" >&2
    exit 1
fi

rm -f "$OUT"
hdiutil create \
    -volname "MenuBarNotes" \
    -srcfolder "$APP" \
    -ov \
    -format UDZO \
    "$OUT"
echo "Built $OUT"

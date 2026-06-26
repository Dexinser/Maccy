#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_APP="/Applications/Maccy.app"
BACKUP_DIR="${ROOT_DIR}/backups"

cd "$ROOT_DIR"

xcodebuild build \
  -project Maccy.xcodeproj \
  -scheme Maccy \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO

BUILD_APP="$(
  xcodebuild -project Maccy.xcodeproj -scheme Maccy -showBuildSettings 2>/dev/null |
    awk -F'= ' '/ BUILT_PRODUCTS_DIR =/{dir=$2} / WRAPPER_NAME = Maccy.app/{name=$2} END{print dir "/" name}'
)"

if [[ ! -d "$BUILD_APP" ]]; then
  echo "Build product not found: $BUILD_APP" >&2
  exit 1
fi

osascript -e 'tell application id "org.p0deje.Maccy" to quit' 2>/dev/null || true
sleep 2
pkill -x Maccy 2>/dev/null || true

mkdir -p "$BACKUP_DIR"
if [[ -d "$INSTALL_APP" ]]; then
  BACKUP_APP="$BACKUP_DIR/Maccy-$(date +%Y%m%d-%H%M%S).app"
  BACKUP_ZIP="${BACKUP_APP%.app}.zip"
  ditto "$INSTALL_APP" "$BACKUP_APP"
  ditto -c -k --sequesterRsrc --keepParent "$BACKUP_APP" "$BACKUP_ZIP"
  rm -rf "$BACKUP_APP"
  echo "Backed up existing app to $BACKUP_ZIP"
fi

rm -rf "$INSTALL_APP"
ditto "$BUILD_APP" "$INSTALL_APP"
/usr/bin/codesign --force --deep --sign - "$INSTALL_APP"
xattr -dr com.apple.quarantine "$INSTALL_APP" 2>/dev/null || true

defaults write org.p0deje.Maccy showFooter -bool false
defaults write org.p0deje.Maccy keepPreviewOpen -bool true
defaults write org.p0deje.Maccy previewDelay -int 200
defaults write org.p0deje.Maccy previewWidth -float 520
defaults write org.p0deje.Maccy activeFilter -string all
defaults delete org.p0deje.Maccy windowSize 2>/dev/null || true

open -a "$INSTALL_APP"
sleep 2

echo "Installed and launched:"
pgrep -fl "/Applications/Maccy.app/Contents/MacOS/Maccy" || true

#!/usr/bin/env bash
set -euo pipefail

APP_NAME="NMSSaveEditor"
BUNDLE_ID="com.cohenmitchell.NMSSaveEditorLegacy"
VERSION="$(tr -d '[:space:]' < VERSION.txt 2>/dev/null || printf '1.0')"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SUPPORT_DIR="$RESOURCES_DIR/NMSSaveEditor"

cd "$ROOT_DIR"

if [[ ! -f NMSSaveEditor.jar ]]; then
  echo "NMSSaveEditor.jar is missing from $ROOT_DIR" >&2
  exit 1
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$SUPPORT_DIR"

cp NMSSaveEditor.jar "$SUPPORT_DIR/"
[[ -f NMSSaveEditor.conf ]] && cp NMSSaveEditor.conf "$SUPPORT_DIR/"
[[ -d db_updater ]] && cp -R db_updater "$SUPPORT_DIR/"

cat >"$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>NMS Save Editor</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

cat >"$MACOS_DIR/$APP_NAME" <<'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SUPPORT_DIR="$APP_DIR/Resources/NMSSaveEditor"
JAR_PATH="$SUPPORT_DIR/NMSSaveEditor.jar"
JAVA_BIN="$(/usr/libexec/java_home 2>/dev/null)/bin/java"

if [[ ! -x "$JAVA_BIN" ]]; then
  JAVA_BIN="$(command -v java || true)"
fi

if [[ -z "$JAVA_BIN" || ! -x "$JAVA_BIN" ]]; then
  osascript -e 'display dialog "Java is required to run NMS Save Editor. Install a Java runtime, then open the app again." buttons {"OK"} default button "OK" with icon caution'
  exit 1
fi

cd "$SUPPORT_DIR"
exec "$JAVA_BIN" -jar "$JAR_PATH"
LAUNCHER

chmod +x "$MACOS_DIR/$APP_NAME"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null
fi

echo "$APP_BUNDLE"

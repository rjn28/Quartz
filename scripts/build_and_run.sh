#!/usr/bin/env bash

set -euo pipefail

readonly MODE="${1:-run}"
readonly APP_NAME="Quartz"
readonly PRODUCT_NAME="QuartzApp"
readonly BUNDLE_ID="com.rjn28.Quartz"
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DIST_DIR="$ROOT_DIR/dist"
readonly APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
readonly APP_CONTENTS="$APP_BUNDLE/Contents"
readonly APP_MACOS="$APP_CONTENTS/MacOS"
readonly APP_RESOURCES="$APP_CONTENTS/Resources"
readonly APP_BINARY="$APP_MACOS/$APP_NAME"
readonly INFO_PLIST="$APP_CONTENTS/Info.plist"

# Stop only the bundle staged by this script. Another installed app can share the
# Quartz process name and must not be interrupted.
pkill -x -f "$APP_BINARY" >/dev/null 2>&1 || true

swift build --package-path "$ROOT_DIR"
build_directory="$(swift build --package-path "$ROOT_DIR" --show-bin-path)"
readonly build_directory
readonly build_binary="$build_directory/$PRODUCT_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
install -m 755 "$build_binary" "$APP_BINARY"
cp "$ROOT_DIR/Packaging/Info.plist" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(tr -d '[:space:]' < "$ROOT_DIR/VERSION")" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$INFO_PLIST"

while IFS= read -r -d '' resource_bundle; do
    cp -R "$resource_bundle" "$APP_RESOURCES/"
done < <(find "$build_directory" -maxdepth 1 -type d -name '*.bundle' -print0)

codesign --force --sign - "$APP_BUNDLE" >/dev/null

open_app() {
    /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
    run)
        open_app
        ;;
    --debug|debug)
        lldb -- "$APP_BINARY"
        ;;
    --logs|logs)
        open_app
        /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
        ;;
    --telemetry|telemetry)
        open_app
        /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
        ;;
    --verify|verify)
        open_app
        sleep 1
        pgrep -x -f "$APP_BINARY" >/dev/null
        ;;
    *)
        echo "Usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
        exit 2
        ;;
esac

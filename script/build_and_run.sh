#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-run}"
case "$MODE" in run|--debug|--logs|--telemetry|--verify) ;; *) echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2; exit 2 ;; esac
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="OnsenPlannerMac"
BUNDLE_ID="Johansson.Vecka"
MAC_BUILD_DIR="$ROOT_DIR/build/mac"
APP_BUNDLE="$MAC_BUILD_DIR/Build/Products/Debug/$APP_NAME.app"
if [[ "$(uname -s)" != Darwin ]] || ! command -v xcodebuild >/dev/null; then
  echo "A Mac with Xcode is required to build and launch Onsen Planner for macOS." >&2
  exit 1
fi
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
python3 "$ROOT_DIR/script/prepare_mac_resources.py"
xcodebuild -project "$ROOT_DIR/OnsenMac.xcodeproj" -scheme OnsenMac \
  -configuration Debug -destination 'platform=macOS' -derivedDataPath "$MAC_BUILD_DIR" build
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
case "$MODE" in
  --debug) /usr/bin/lldb -- "$APP_BINARY" ;;
  --logs) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\"" ;;
  --telemetry) /usr/bin/open -n "$APP_BUNDLE"; /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\"" ;;
  --verify) /usr/bin/open -n "$APP_BUNDLE"; sleep 1; pgrep -x "$APP_NAME" >/dev/null ;;
  run) /usr/bin/open -n "$APP_BUNDLE" ;;
esac

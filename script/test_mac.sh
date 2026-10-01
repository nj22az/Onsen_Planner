#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$(uname -s)" != Darwin ]] || ! command -v xcodebuild >/dev/null; then
  echo "A Mac with Xcode is required to run native Mac tests." >&2
  exit 1
fi
python3 "$ROOT_DIR/script/prepare_mac_resources.py"
TEST_ARGS=()
case "${1:-all}" in
  all) ;;
  --unit-only) TEST_ARGS=(-only-testing:OnsenMacTests) ;;
  *) echo "usage: $0 [--unit-only]" >&2; exit 2 ;;
esac
xcodebuild -project "$ROOT_DIR/OnsenMac.xcodeproj" -scheme OnsenMac \
  -destination 'platform=macOS' -derivedDataPath "$ROOT_DIR/build/mac" \
  -resultBundlePath "$ROOT_DIR/build/MacTests-$(date -u +%Y%m%dT%H%M%SZ).xcresult" \
  "${TEST_ARGS[@]}" test

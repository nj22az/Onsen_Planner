#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

PROJECT_FILE="Vecka.xcodeproj"
SCHEME_NAME="Vecka"
DERIVED_DATA="${VECKA_DERIVED_DATA:-$PWD/build/DerivedData}"
RESULT_PATH="${VECKA_TEST_RESULTS:-$PWD/build/TestResults-$(date +%Y%m%d-%H%M%S).xcresult}"

validate_project() {
    command -v xcodebuild >/dev/null || { echo 'Xcode is required. Run this command on a Mac.' >&2; exit 1; }
    xcodebuild -version
    test -f "$PROJECT_FILE/xcshareddata/xcschemes/Vecka.xcscheme"
}

simulator_destination() {
    if [ -n "${VECKA_DESTINATION:-}" ]; then
        printf '%s\n' "$VECKA_DESTINATION"
        return
    fi
    xcrun simctl list devices available --json | python3 -c '
import json, re, sys
devices = json.load(sys.stdin)["devices"]
candidates = []
for runtime, rows in devices.items():
    match = re.search(r"iOS-(\d+)(?:-(\d+))?", runtime)
    if not match or int(match[1]) < 18:
        continue
    for row in rows:
        if row.get("isAvailable") and row["name"].startswith("iPhone"):
            candidates.append((int(match[1]), int(match[2] or 0), row["state"] == "Booted", row["udid"]))
if not candidates:
    sys.exit("No available iPhone simulator with iOS 18 or newer. Install one in Xcode or set VECKA_DESTINATION.")
print("platform=iOS Simulator,id=" + sorted(candidates, reverse=True)[0][3])'
}

build_project() {
    python3 scripts/validate-release-config.py
    xcodebuild build -project "$PROJECT_FILE" -scheme "$SCHEME_NAME" \
        -destination 'generic/platform=iOS Simulator' -configuration "$1" \
        -derivedDataPath "$DERIVED_DATA" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
    python3 scripts/validate-release-config.py --app "$DERIVED_DATA/Build/Products/$1-iphonesimulator/Vecka.app"
}

case "${1:-help}" in
    lint) ./scripts/lint-design-system.sh ;;
    validate-docs) ./scripts/validate-docs.sh --quiet ;;
    validate) validate_project ;;
    build|build-release)
        validate_project
        config=Debug
        if [ "$1" = build-release ]; then config=Release; fi
        build_project "$config"
        ;;
    test)
        validate_project
        ./scripts/lint-design-system.sh
        ./scripts/validate-docs.sh --quiet
        python3 scripts/validate-release-config.py
        mkdir -p "$(dirname "$RESULT_PATH")"
        xcodebuild test -project "$PROJECT_FILE" -scheme "$SCHEME_NAME" \
            -destination "$(simulator_destination)" -configuration Debug \
            -derivedDataPath "$DERIVED_DATA" -resultBundlePath "$RESULT_PATH" \
            -parallel-testing-enabled NO -only-testing:VeckaTests \
            CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
        ;;
    widget-test)
        validate_project
        xcodebuild build -project "$PROJECT_FILE" -target VeckaWidgetExtension \
            -sdk iphonesimulator -configuration Debug CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
        ;;
    clean)
        validate_project
        xcodebuild clean -project "$PROJECT_FILE" -scheme "$SCHEME_NAME" \
            -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DERIVED_DATA"
        ;;
    archive)
        validate_project
        # Unsigned archive only; distribution signing and upload remain separate.
        xcodebuild archive -project "$PROJECT_FILE" -scheme "$SCHEME_NAME" \
            -destination 'generic/platform=iOS' -configuration Release \
            -archivePath "$PWD/build/Vecka.xcarchive" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
        ;;
    help|--help|-h)
        echo 'Usage: ./build.sh [build|build-release|test|widget-test|lint|validate-docs|validate|clean|archive]'
        echo 'Set VECKA_DESTINATION to override the automatically selected iOS simulator.'
        ;;
    *) echo "Unknown command: $1" >&2; exit 1 ;;
esac

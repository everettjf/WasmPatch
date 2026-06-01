#!/usr/bin/env bash
#
# validate-swiftui-app.sh — build the SwiftUI demo Xcode app and run its
# headless self-test, which loads the bundled patch and confirms an
# @objc dynamic Swift method was hot-patched.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT_DIR/Demo/WasmPatch-SwiftUI/WasmPatch-SwiftUI.xcodeproj"
SCHEME="WasmPatch-SwiftUI"
DERIVED="$ROOT_DIR/.build/swiftui-demo"
APP="$DERIVED/Build/Products/Debug/WasmPatch-SwiftUI.app/Contents/MacOS/WasmPatch-SwiftUI"

log()  { printf '[swiftui-validate] %s\n' "$1"; }
fail() { printf '[swiftui-validate] ERROR: %s\n' "$1" >&2; exit 1; }

command -v xcodebuild >/dev/null 2>&1 || fail "xcodebuild is required"

log "building the SwiftUI demo app"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -derivedDataPath "$DERIVED" -destination 'platform=macOS' build >/dev/null
[ -x "$APP" ] || fail "built app binary not found: $APP"

log "running headless self-test"
set +e
OUT="$(WASMPATCH_AUTOTEST=1 "$APP" 2>&1)"
CODE=$?
set -e
echo "$OUT"

[ $CODE -eq 0 ] || fail "self-test exited with code $CODE"
echo "$OUT" | grep -q "WASMPATCH_AUTOTEST_PASS" || fail "PASS marker missing"
log "SwiftUI app validation passed"

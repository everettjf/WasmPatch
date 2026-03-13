#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$ROOT_DIR/Demo/WasmPatch-macOS/WasmPatch-macOS.xcworkspace"
SCHEME="WasmPatch-macOS"
DERIVED_DATA="$ROOT_DIR/.build/macos-validation"
LOG_FILE="$DERIVED_DATA/run.log"
APP_PATH="$DERIVED_DATA/Build/Products/Debug/WasmPatch-macOS.app"

log() {
  printf '[macos-validate] %s\n' "$1"
}

fail() {
  printf '[macos-validate] ERROR: %s\n' "$1" >&2
  exit 1
}

command -v pod >/dev/null 2>&1 || fail "CocoaPods is required"
command -v xcodebuild >/dev/null 2>&1 || fail "xcodebuild is required"

log "installing demo pods"
pod install --project-directory="$ROOT_DIR/Demo/WasmPatch-macOS" >/dev/null

log "building macOS validation app"
xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  build >/dev/null

[ -x "$APP_PATH/Contents/MacOS/WasmPatch-macOS" ] || fail "built app not found: $APP_PATH"

log "running macOS validation app"
set +e
WASMPATCH_AUTOTEST=1 "$APP_PATH/Contents/MacOS/WasmPatch-macOS" >"$LOG_FILE" 2>&1
APP_EXIT_CODE=$?
set -e

cat "$LOG_FILE"

[ $APP_EXIT_CODE -eq 0 ] || fail "validation app exited with code $APP_EXIT_CODE"
rg -q "WASMPATCH_AUTOTEST_PASS" "$LOG_FILE" || fail "PASS marker missing"
rg -q "WasmPatch validation passed" "$LOG_FILE" || fail "validation summary missing"
rg -q "plain: hello-c-string" "$LOG_FILE" || fail "CallMe echoCString log missing"
rg -q "plain: Hello from Objective-C" "$LOG_FILE" || fail "CallMe staticCString log missing"

log "macOS validation passed"

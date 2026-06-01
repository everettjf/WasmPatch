#!/usr/bin/env bash
#
# validate-remote.sh — end-to-end check of WAPPatchManager's remote delivery.
#
# Serves the testcase wasm over a local HTTP server, then runs the macOS demo
# with WASMPATCH_MANAGER_URL/SHA set so the app downloads, SHA-256-verifies,
# caches, and applies the patch through WAPPatchManager before asserting the
# same behaviour as the offline validation.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$ROOT_DIR/Demo/WasmPatch-macOS/WasmPatch-macOS.xcworkspace"
SCHEME="WasmPatch-macOS"
DERIVED_DATA="$ROOT_DIR/.build/macos-validation"
APP="$DERIVED_DATA/Build/Products/Debug/WasmPatch-macOS.app/Contents/MacOS/WasmPatch-macOS"
WASM="$ROOT_DIR/TestCase/WasmPatch-TestCase/Assets/script.bundle/objc.wasm"

log()  { printf '[remote-validate] %s\n' "$1"; }
fail() { printf '[remote-validate] ERROR: %s\n' "$1" >&2; exit 1; }

[ -f "$WASM" ] || fail "missing wasm fixture: $WASM (run TestCase/compile-testcase.sh)"
command -v xcodebuild >/dev/null 2>&1 || fail "xcodebuild is required"
command -v python3 >/dev/null 2>&1 || fail "python3 is required"

SHA256="$(shasum -a 256 "$WASM" | awk '{print $1}')"
log "fixture sha256: $SHA256"

# Serve the directory containing objc.wasm on an ephemeral port.
SERVE_DIR="$(dirname "$WASM")"
PORT=8723
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$SERVE_DIR" >/dev/null 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null || true' EXIT
sleep 1
log "serving $SERVE_DIR at http://localhost:$PORT"

log "building macOS demo"
xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" build >/dev/null
[ -x "$APP" ] || fail "built app not found: $APP"

log "running remote-delivery validation"
set +e
OUT="$(WASMPATCH_AUTOTEST=1 \
       WASMPATCH_MANAGER_URL="http://localhost:$PORT/objc.wasm" \
       WASMPATCH_MANAGER_SHA="$SHA256" \
       "$APP" 2>&1)"
CODE=$?
set -e
echo "$OUT"

[ $CODE -eq 0 ] || fail "app exited with code $CODE"
echo "$OUT" | grep -q "WASMPATCH_AUTOTEST_PASS" || fail "PASS marker missing"
echo "$OUT" | grep -q "manager: applied cached patch" || fail "manager apply marker missing"
log "remote-delivery validation passed"

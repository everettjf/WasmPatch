#!/usr/bin/env bash
#
# validate-signing.sh — verify asymmetric patch signing end-to-end.
#
# Generates an EC P-256 key, signs the testcase wasm, and runs the macOS demo
# with the public key + signature. A valid signature must load; a tampered
# signature must be rejected with WAPPatchLoaderErrorCodeSignatureInvalid (8).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$ROOT_DIR/Demo/WasmPatch-macOS/WasmPatch-macOS.xcworkspace"
SCHEME="WasmPatch-macOS"
DERIVED_DATA="$ROOT_DIR/.build/macos-validation"
APP="$DERIVED_DATA/Build/Products/Debug/WasmPatch-macOS.app/Contents/MacOS/WasmPatch-macOS"
WASM="$ROOT_DIR/TestCase/WasmPatch-TestCase/Assets/script.bundle/objc.wasm"
KEY="$ROOT_DIR/.build/signing/patch_key.pem"

log()  { printf '[sign-validate] %s\n' "$1"; }
fail() { printf '[sign-validate] ERROR: %s\n' "$1" >&2; exit 1; }

[ -f "$WASM" ] || fail "missing wasm fixture: $WASM"
command -v openssl >/dev/null 2>&1 || fail "openssl is required"
mkdir -p "$(dirname "$KEY")"

log "generating key + signing fixture"
"$ROOT_DIR/Tool/wasmpatch" keygen "$KEY" >/dev/null
PUB="$(openssl ec -in "$KEY" -pubout -outform DER 2>/dev/null | tail -c 65 | openssl base64 -A)"
SIG="$(openssl dgst -sha256 -sign "$KEY" "$WASM" | openssl base64 -A)"
# A tampered signature: flip the last base64 char.
BAD_SIG="${SIG%?}$([ "${SIG: -1}" = "A" ] && echo B || echo A)"

log "building macOS demo"
xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" build >/dev/null
[ -x "$APP" ] || fail "built app not found: $APP"

log "case 1: valid signature should load"
set +e
OUT="$(WASMPATCH_AUTOTEST=1 WASMPATCH_PUBKEY="$PUB" WASMPATCH_SIG="$SIG" "$APP" 2>&1)"
CODE=$?
set -e
echo "$OUT" | grep -E "signed load|validation passed|AUTOTEST" || true
[ $CODE -eq 0 ] && echo "$OUT" | grep -q "WASMPATCH_AUTOTEST_PASS" || fail "valid signature did not load"
log "case 1 passed"

log "case 2: tampered signature must be rejected"
set +e
OUT2="$(WASMPATCH_AUTOTEST=1 WASMPATCH_PUBKEY="$PUB" WASMPATCH_SIG="$BAD_SIG" "$APP" 2>&1)"
CODE2=$?
set -e
echo "$OUT2" | grep -E "signed load failed|AUTOTEST_FAIL" || true
[ $CODE2 -ne 0 ] || fail "tampered signature was NOT rejected (app exited 0)"
echo "$OUT2" | grep -q "code=8" || fail "expected signature error code 8"
log "case 2 passed (rejected with code 8)"

log "signing validation passed"

#!/usr/bin/env bash
#
# validate-swift.sh — end-to-end Swift integration check.
#
# Compiles the demo patch, then runs the SwiftPM example which defines an
# `@objc dynamic` Swift method, loads the patch, and asserts the method was
# replaced. Proves Swift apps can hook Swift methods through WasmPatch.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PATCH_SRC="$ROOT_DIR/Demo/SwiftExample/patch/greeting.c"
PATCH_WASM="$ROOT_DIR/.build/swift-demo/greeting.wasm"

log()  { printf '[swift-validate] %s\n' "$1"; }
fail() { printf '[swift-validate] ERROR: %s\n' "$1" >&2; exit 1; }

mkdir -p "$(dirname "$PATCH_WASM")"

log "compiling demo patch"
"$ROOT_DIR/Tool/wasmpatch" build "$PATCH_SRC" "$PATCH_WASM" >/dev/null || fail "patch compile failed"

log "building + running Swift example"
set +e
OUT="$(cd "$ROOT_DIR" && swift run WasmPatchSwiftExample "$PATCH_WASM" 2>&1)"
CODE=$?
set -e
echo "$OUT" | grep -vE "^\[?[0-9]+/[0-9]+\]|Compiling|Building|Build complete|Linking|warning:"

[ $CODE -eq 0 ] || fail "swift example exited with code $CODE"
echo "$OUT" | grep -q "SWIFT_DEMO_PASS" || fail "SWIFT_DEMO_PASS marker missing"
log "swift integration validation passed"

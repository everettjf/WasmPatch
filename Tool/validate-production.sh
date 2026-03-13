#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TESTCASE_DIR="$ROOT_DIR/TestCase"
FIXTURE_C="$TESTCASE_DIR/WasmPatch-TestCase/Assets/script.bundle/objc.c"
FIXTURE_WASM="$TESTCASE_DIR/WasmPatch-TestCase/Assets/script.bundle/objc.wasm"
FIXTURE_WAT="$TESTCASE_DIR/WasmPatch-TestCase/Assets/script.bundle/objc.wasm.wat"

log() {
  printf '[validate] %s\n' "$1"
}

fail() {
  printf '[validate] ERROR: %s\n' "$1" >&2
  exit 1
}

check_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    return 1
  fi
}

log "repo: $ROOT_DIR"

check_cmd pod || fail "CocoaPods is required. Install it with: gem install cocoapods"
log "running pod lib lint"
(
  cd "$ROOT_DIR"
  pod lib lint WasmPatch.podspec --allow-warnings
)

if ! check_cmd clang; then
  fail "clang is required to build wasm fixtures"
fi

if ! check_cmd wasm-ld; then
  fail "wasm-ld is required to build wasm fixtures. Install LLVM WebAssembly tools first."
fi

if ! check_cmd wasm2wat; then
  fail "wasm2wat is required to inspect wasm fixtures. Install wabt first."
fi

log "building wasm testcase fixture"
(
  cd "$TESTCASE_DIR"
  sh compile-testcase.sh
)

[ -f "$FIXTURE_C" ] || fail "fixture source missing: $FIXTURE_C"
[ -f "$FIXTURE_WASM" ] || fail "fixture wasm missing after build: $FIXTURE_WASM"
[ -f "$FIXTURE_WAT" ] || fail "fixture wat missing after build: $FIXTURE_WAT"

log "checking fixture contents"
if ! rg -q "classCString|instanceCString|classScore|instanceScore" "$FIXTURE_C"; then
  fail "fixture source does not include the expected production-ready coverage markers"
fi

if ! rg -q "echoCString:|staticCString|classCString|instanceCString" "$FIXTURE_WAT"; then
  fail "fixture wat does not include the expected exported selector strings"
fi

log "running macOS validation"
(
  cd "$ROOT_DIR"
  sh Tool/run-macos-validation.sh
)

log "validation passed"

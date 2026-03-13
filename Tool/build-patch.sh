#!/usr/bin/env bash

set -euo pipefail

help() {
  cat <<'EOF'
Usage:
  sh Tool/build-patch.sh <input.c> [output.wasm]

Examples:
  sh Tool/build-patch.sh patch/login_fix.c
  sh Tool/build-patch.sh patch/login_fix.c build/login_fix.wasm

Behavior:
  - If output.wasm is omitted, the script writes next to the input file.
  - It delegates the actual compilation to Tool/c2wasm.sh.
EOF
  exit 1
}

if [ "${1:-}" = "" ]; then
  help
fi

INPUT_FILE="$1"
if [ ! -f "$INPUT_FILE" ]; then
  echo "input file not found: $INPUT_FILE" >&2
  exit 1
fi

if [ "${2:-}" = "" ]; then
  OUTPUT_FILE="${INPUT_FILE%.*}.wasm"
else
  OUTPUT_FILE="$2"
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "[build-patch] input: $INPUT_FILE"
echo "[build-patch] output: $OUTPUT_FILE"

sh "$ROOT_DIR/Tool/c2wasm.sh" "$INPUT_FILE" "$OUTPUT_FILE"

echo "[build-patch] done"

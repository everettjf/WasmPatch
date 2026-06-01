#!/usr/bin/env bash

set -euo pipefail


help()
{
    echo ""
    echo "Usage: $0 <input.c> <output.wasm>"
    echo "Environment:"
    echo "  CLANG_BIN   Override clang executable"
    echo "  WASM2WAT    Override wasm2wat executable"
    echo "  WASM_LD_BIN Override wasm-ld executable"
    echo "  WAP_SDK_DIR Override author SDK include dir (default: <repo>/Tool/sdk)"
    echo "  WAP_EMIT_META=0  Disable .meta.json / .sha256 sidecar generation"
    exit 1 # Exit script after printing help
}

if [ -z "$1" ] || [ -z "$2" ]
then
   echo "input or output parameter is empty"
   help
fi

if [ ! -f "$1" ]
then
   echo "input file not found: $1"
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WAP_SDK_DIR="${WAP_SDK_DIR:-$SCRIPT_DIR/sdk}"

CLANG_BIN="${CLANG_BIN:-$(command -v clang || true)}"
WASM2WAT="${WASM2WAT:-$(command -v wasm2wat || true)}"
WASM_LD_BIN="${WASM_LD_BIN:-$(command -v wasm-ld || true)}"

if [ -z "$CLANG_BIN" ]
then
   echo "clang not found. Install LLVM first."
   exit 1
fi

if [ -z "$WASM_LD_BIN" ]
then
   echo "wasm-ld not found. Install LLVM with WebAssembly tools or set WASM_LD_BIN."
   exit 1
fi

export PATH="$(dirname "$WASM_LD_BIN"):$PATH"

# sample:
#
# clang \
#    --target=wasm32 \
# +  -O3 \ # Agressive optimizations
# +  -flto \ # Add metadata for link-time optimizations
#    -nostdlib \
#    -Wl,--no-entry \
#    -Wl,--export-all \
#    -Wl,--allow-undefined \
# +  -Wl,--lto-O3 \ # Aggressive link-time optimizations
#    -o add.wasm \
#    add.c

SDK_INCLUDE=()
if [ -d "$WAP_SDK_DIR" ]
then
  SDK_INCLUDE=(-I "$WAP_SDK_DIR")
fi

"$CLANG_BIN" \
  --target=wasm32 \
  -O3 \
  -flto \
  -Werror \
  -nostdlib \
  "${SDK_INCLUDE[@]}" \
  -Wl,--export-all \
  -Wl,--no-entry \
  -Wl,--allow-undefined \
  -Wl,--lto-O3 \
  -o "$2" \
  "$1"

if [ -n "$WASM2WAT" ]
then
  "$WASM2WAT" "$2" -o "$2.wat"
else
  echo "wasm2wat not found, skipped .wat generation"
fi

echo "compiled wasm: $2"

# Emit sidecar metadata (sha256 + size) so hosts can verify the payload with
# WAPPatchLoaderOptions.expectedSHA256Hex without a separate step.
if [ "${WAP_EMIT_META:-1}" != "0" ]
then
  SHA_CMD="$(command -v shasum || true)"
  if [ -n "$SHA_CMD" ]
  then
    SHA256_HEX="$("$SHA_CMD" -a 256 "$2" | awk '{print $1}')"
  else
    SHA256_HEX="$(openssl dgst -sha256 "$2" | awk '{print $NF}')"
  fi
  BYTES="$(wc -c < "$2" | tr -d ' ')"
  printf '%s' "$SHA256_HEX" > "$2.sha256"
  cat > "$2.meta.json" <<EOF
{
  "wasm": "$(basename "$2")",
  "sha256": "$SHA256_HEX",
  "bytes": $BYTES,
  "source": "$(basename "$1")"
}
EOF
  echo "sha256: $SHA256_HEX ($BYTES bytes)"
fi

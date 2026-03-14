#!/usr/bin/env bash

set -euo pipefail

brew install llvm lld wabt

LLVM_PREFIX="$(brew --prefix llvm)"
LLD_PREFIX="$(brew --prefix lld)"

cat <<EOF
LLVM installed.

Recommended shell setup:
  export PATH="$LLVM_PREFIX/bin:$LLD_PREFIX/bin:\$PATH"

You can now run:
  sh Tool/c2wasm.sh input.c output.wasm
EOF

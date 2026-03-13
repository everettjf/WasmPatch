#!/usr/bin/env bash

set -euo pipefail

brew install llvm wabt

LLVM_PREFIX="$(brew --prefix llvm)"

cat <<EOF
LLVM installed.

Recommended shell setup:
  export PATH="$LLVM_PREFIX/bin:\$PATH"

You can now run:
  sh Tool/c2wasm.sh input.c output.wasm
EOF


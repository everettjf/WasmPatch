#!/usr/bin/env bash

set -euo pipefail

gen_c()
{
    sh ../Tool/build-patch.sh "$1.c" "$1.wasm"
}

gen_c WasmPatch-TestCase/Assets/script.bundle/objc

echo "testcase wasm assets refreshed"

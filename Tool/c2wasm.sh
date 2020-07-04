#!/bin/bash

echo "First arg: $1"
echo "Second arg: $2"


help()
{
    echo ""
    echo "Usage: $0 <input:c-source-file> <output:wasm-file>"
    exit 1 # Exit script after printing help
}

if [ -z "$1" ] || [ -z "$2" ]
then
   echo "Some or all of the parameters are empty";
   help
fi

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

clang --target=wasm32 -O3 -flto --no-standard-libraries -Wl,--export-all -Wl,--no-entry -Wl,--allow-undefined -Wl,--lto-O3 -o $2 $1


wasm2wat $2 -o $2.wat

echo "Done:)"
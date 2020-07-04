

gen_c()
{
    sh ../Tool/c2wasm.sh $1.c $1.wasm
}

gen_c WasmPatch-TestCase/Assets/script.bundle/objc


echo "All Done:)"

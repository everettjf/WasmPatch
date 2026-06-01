(module $objc.wasm
  (type (;0;) (func (param i32) (result i32)))
  (type (;1;) (func (param i32) (result i64)))
  (type (;2;) (func (param f64 f64 f64 f64) (result i64)))
  (type (;3;) (func (param i64 i32) (result i64)))
  (type (;4;) (func (param i64) (result f64)))
  (type (;5;) (func (result i64)))
  (type (;6;) (func (param i64 i64) (result i32)))
  (type (;7;) (func (param i64 i64) (result i64)))
  (type (;8;) (func (param i64) (result i32)))
  (type (;9;) (func (param i32 i32 i64) (result i64)))
  (type (;10;) (func (param i64 i32) (result i32)))
  (type (;11;) (func (param i64 i32) (result f64)))
  (type (;12;) (func (param i64 i32 i32) (result i32)))
  (type (;13;) (func (param i64 i32 f64) (result i32)))
  (type (;14;) (func (param i64 i32 i64) (result i32)))
  (type (;15;) (func (param i32 i32) (result i64)))
  (type (;16;) (func (param i32 i32 i64 i64) (result i64)))
  (type (;17;) (func (param i32 i32 i32) (result i32)))
  (type (;18;) (func (param i32 i32 i64 i64 i64 i64) (result i64)))
  (type (;19;) (func (param f64) (result i64)))
  (type (;20;) (func (param i64) (result i64)))
  (type (;21;) (func (param f32) (result i64)))
  (type (;22;) (func))
  (type (;23;) (func (param i64 i32 i64) (result i64)))
  (type (;24;) (func (result i32)))
  (import "env" "print_string" (func $print_string (type 0)))
  (import "env" "new_objc_nsstring" (func $new_objc_nsstring (type 1)))
  (import "env" "alloc_string" (func $alloc_string (type 1)))
  (import "env" "alloc_cgrect" (func $alloc_cgrect (type 2)))
  (import "env" "get_array_item" (func $get_array_item (type 3)))
  (import "env" "cgrect_get_x" (func $cgrect_get_x (type 4)))
  (import "env" "cgrect_get_y" (func $cgrect_get_y (type 4)))
  (import "env" "cgrect_get_width" (func $cgrect_get_width (type 4)))
  (import "env" "cgrect_get_height" (func $cgrect_get_height (type 4)))
  (import "env" "alloc_array" (func $alloc_array (type 5)))
  (import "env" "append_array" (func $append_array (type 6)))
  (import "env" "invoke_block" (func $invoke_block (type 7)))
  (import "env" "dealloc_array" (func $dealloc_array (type 8)))
  (import "env" "call_class_method_1" (func $call_class_method_1 (type 9)))
  (import "env" "struct_get_int32" (func $struct_get_int32 (type 10)))
  (import "env" "struct_get_double" (func $struct_get_double (type 11)))
  (import "env" "struct_get_int64" (func $struct_get_int64 (type 3)))
  (import "env" "alloc_struct" (func $alloc_struct (type 1)))
  (import "env" "struct_set_int32" (func $struct_set_int32 (type 12)))
  (import "env" "struct_set_double" (func $struct_set_double (type 13)))
  (import "env" "struct_set_int64" (func $struct_set_int64 (type 14)))
  (import "env" "call_class_method_0" (func $call_class_method_0 (type 15)))
  (import "env" "call_class_method_2" (func $call_class_method_2 (type 16)))
  (import "env" "alloc_objc_class" (func $alloc_objc_class (type 1)))
  (import "env" "call_instance_method_0" (func $call_instance_method_0 (type 3)))
  (import "env" "dealloc_object" (func $dealloc_object (type 8)))
  (import "env" "replace_class_method" (func $replace_class_method (type 17)))
  (import "env" "replace_instance_method" (func $replace_instance_method (type 17)))
  (import "env" "call_class_method_4" (func $call_class_method_4 (type 18)))
  (import "env" "alloc_double" (func $alloc_double (type 19)))
  (import "env" "create_block" (func $create_block (type 15)))
  (import "env" "print_object" (func $print_object (type 8)))
  (import "env" "new_objc_nsnumber_int" (func $new_objc_nsnumber_int (type 1)))
  (import "env" "alloc_int32" (func $alloc_int32 (type 1)))
  (import "env" "alloc_int64" (func $alloc_int64 (type 20)))
  (import "env" "alloc_float" (func $alloc_float (type 21)))
  (import "env" "call_class_method_param" (func $call_class_method_param (type 9)))
  (func $__wasm_call_ctors (type 22))
  (func $my_class_ReplaceMe_request (type 10) (param i64 i32) (result i32)
    i32.const 65692
    call $print_string
    drop
    i32.const 0)
  (func $my_class_ReplaceMe_requestfromto (type 14) (param i64 i32 i64) (result i32)
    i32.const 66554
    call $print_string
    drop
    i32.const 0)
  (func $my_instance_ReplaceMe_request (type 10) (param i64 i32) (result i32)
    i32.const 65663
    call $print_string
    drop
    i32.const 0)
  (func $my_instance_ReplaceMe_requestfromto (type 14) (param i64 i32 i64) (result i32)
    i32.const 66510
    call $print_string
    drop
    i32.const 0)
  (func $my_class_ReplaceMe_classtoken (type 3) (param i64 i32) (result i64)
    i32.const 66061
    call $new_objc_nsstring)
  (func $my_class_ReplaceMe_classmagicnumber (type 10) (param i64 i32) (result i32)
    i32.const 42)
  (func $my_class_ReplaceMe_classfeatureenabled (type 10) (param i64 i32) (result i32)
    i32.const 1)
  (func $my_class_ReplaceMe_classscore (type 11) (param i64 i32) (result f64)
    f64.const 0x1.3p+3 (;=9.5;))
  (func $my_class_ReplaceMe_classcstring (type 3) (param i64 i32) (result i64)
    i32.const 66288
    call $alloc_string)
  (func $my_instance_ReplaceMe_instancetoken (type 3) (param i64 i32) (result i64)
    i32.const 66082
    call $new_objc_nsstring)
  (func $my_instance_ReplaceMe_instancemagicnumber (type 10) (param i64 i32) (result i32)
    i32.const 43)
  (func $my_instance_ReplaceMe_instancefeatureenabled (type 10) (param i64 i32) (result i32)
    i32.const 1)
  (func $my_instance_ReplaceMe_instancescore (type 11) (param i64 i32) (result f64)
    f64.const 0x1.18p+3 (;=8.75;))
  (func $my_instance_ReplaceMe_instancecstring (type 3) (param i64 i32) (result i64)
    i32.const 66327
    call $alloc_string)
  (func $my_class_ReplaceMe_classbounds (type 3) (param i64 i32) (result i64)
    f64.const 0x1p+0 (;=1;)
    f64.const 0x1p+1 (;=2;)
    f64.const 0x1.8p+1 (;=3;)
    f64.const 0x1p+2 (;=4;)
    call $alloc_cgrect)
  (func $my_instance_ReplaceMe_sumofrect (type 14) (param i64 i32 i64) (result i32)
    local.get 2
    i32.const 0
    call $get_array_item
    local.tee 2
    call $cgrect_get_x
    local.get 2
    call $cgrect_get_y
    f64.add
    local.get 2
    call $cgrect_get_width
    f64.add
    local.get 2
    call $cgrect_get_height
    f64.add
    i32.trunc_sat_f64_s)
  (func $my_instance_ReplaceMe_fetch (type 14) (param i64 i32 i64) (result i32)
    (local i64)
    local.get 2
    i32.const 0
    call $get_array_item
    local.set 3
    call $alloc_array
    local.tee 2
    i32.const 66168
    call $new_objc_nsstring
    call $append_array
    drop
    local.get 3
    local.get 2
    call $invoke_block
    drop
    local.get 2
    call $dealloc_array
    drop
    i32.const 0)
  (func $my_created_block (type 20) (param i64) (result i64)
    i32.const 66673
    i32.const 66827
    local.get 0
    i32.const 0
    call $get_array_item
    call $call_class_method_1
    drop
    i64.const 0)
  (func $my_instance_ReplaceMe_sumtriple (type 23) (param i64 i32 i64) (result i64)
    (local i32)
    local.get 2
    i32.const 0
    call $get_array_item
    local.tee 2
    i32.const 0
    call $struct_get_int32
    local.set 3
    local.get 2
    i32.const 8
    call $struct_get_double
    i64.trunc_sat_f64_s
    local.get 3
    i64.extend_i32_s
    i64.add
    local.get 2
    i32.const 16
    call $struct_get_int64
    i64.add)
  (func $my_class_ReplaceMe_buildtriple (type 3) (param i64 i32) (result i64)
    (local i64)
    i32.const 65536
    call $alloc_struct
    local.tee 2
    i32.const 0
    i32.const 7
    call $struct_set_int32
    drop
    local.get 2
    i32.const 8
    f64.const 0x1.4p+1 (;=2.5;)
    call $struct_set_double
    drop
    local.get 2
    i32.const 16
    i64.const 100
    call $struct_set_int64
    drop
    local.get 2)
  (func $entry (type 24) (result i32)
    (local i64 i64 i64)
    i32.const 66673
    i32.const 66184
    call $call_class_method_0
    drop
    i32.const 66673
    i32.const 66979
    i32.const 66131
    call $new_objc_nsstring
    local.tee 0
    call $call_class_method_1
    drop
    i32.const 66673
    i32.const 66965
    i32.const 65575
    call $new_objc_nsstring
    local.tee 1
    i32.const 65552
    call $new_objc_nsstring
    local.tee 2
    call $call_class_method_2
    drop
    local.get 2
    call $dealloc_object
    drop
    local.get 1
    call $dealloc_object
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 66673
    call $alloc_objc_class
    local.tee 0
    i32.const 66184
    call $call_instance_method_0
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 66680
    i32.const 65713
    i32.const 65606
    call $replace_class_method
    drop
    i32.const 66680
    i32.const 66869
    i32.const 65926
    call $replace_class_method
    drop
    i32.const 66680
    i32.const 66106
    i32.const 65995
    call $replace_class_method
    drop
    i32.const 66680
    i32.const 65889
    i32.const 65811
    call $replace_class_method
    drop
    i32.const 66680
    i32.const 66779
    i32.const 66695
    call $replace_class_method
    drop
    i32.const 66680
    i32.const 66485
    i32.const 66419
    call $replace_class_method
    drop
    i32.const 66680
    i32.const 66367
    i32.const 66218
    call $replace_class_method
    drop
    i32.const 66680
    i32.const 65799
    i32.const 65768
    call $replace_class_method
    drop
    i32.const 66680
    i32.const 65713
    i32.const 65633
    call $replace_instance_method
    drop
    i32.const 66680
    i32.const 66869
    i32.const 65959
    call $replace_instance_method
    drop
    i32.const 66680
    i32.const 66117
    i32.const 66025
    call $replace_instance_method
    drop
    i32.const 66680
    i32.const 65906
    i32.const 65847
    call $replace_instance_method
    drop
    i32.const 66680
    i32.const 66799
    i32.const 66734
    call $replace_instance_method
    drop
    i32.const 66680
    i32.const 66496
    i32.const 66449
    call $replace_instance_method
    drop
    i32.const 66680
    i32.const 66380
    i32.const 66250
    call $replace_instance_method
    drop
    i32.const 66680
    i32.const 66846
    i32.const 65736
    call $replace_instance_method
    drop
    i32.const 66680
    i32.const 66905
    i32.const 66190
    call $replace_instance_method
    drop
    i32.const 66680
    i32.const 66954
    i32.const 66598
    call $replace_instance_method
    drop
    i32.const 66680
    i32.const 66661
    i32.const 66630
    call $replace_class_method
    drop
    i32.const 66673
    i32.const 66926
    i32.const 66673
    i32.const 66857
    f64.const 0x1p+0 (;=1;)
    f64.const 0x1p+1 (;=2;)
    f64.const 0x1.8p+1 (;=3;)
    f64.const 0x1p+2 (;=4;)
    call $alloc_cgrect
    local.tee 1
    call $call_class_method_1
    local.tee 0
    call $cgrect_get_x
    call $alloc_double
    local.get 0
    call $cgrect_get_y
    call $alloc_double
    local.get 0
    call $cgrect_get_width
    call $alloc_double
    local.get 0
    call $cgrect_get_height
    call $alloc_double
    call $call_class_method_4
    drop
    local.get 1
    call $dealloc_object
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 66673
    i32.const 66885
    i32.const 66151
    i32.const 66822
    call $create_block
    call $call_class_method_1
    drop
    i32.const 65593
    call $print_string
    drop
    i32.const 66690
    call $new_objc_nsstring
    local.set 0
    i32.const 66410
    call $new_objc_nsstring
    local.set 1
    local.get 0
    call $print_object
    drop
    local.get 1
    call $print_object
    drop
    local.get 0
    call $dealloc_object
    drop
    local.get 1
    call $dealloc_object
    drop
    i32.const 1
    call $new_objc_nsnumber_int
    local.tee 0
    call $print_object
    drop
    local.get 0
    call $dealloc_object
    drop
    call $alloc_array
    local.tee 0
    i32.const 10
    call $alloc_int32
    call $append_array
    drop
    local.get 0
    i64.const 666
    call $alloc_int64
    call $append_array
    drop
    local.get 0
    f32.const 0x1.f147aep+2 (;=7.77;)
    call $alloc_float
    call $append_array
    drop
    local.get 0
    f64.const 0x1.9071c432ca57ap+7 (;=200.222;)
    call $alloc_double
    call $append_array
    drop
    local.get 0
    i32.const 65721
    call $new_objc_nsstring
    call $append_array
    drop
    local.get 0
    i32.const 65563
    call $alloc_string
    call $append_array
    drop
    i32.const 66673
    i32.const 66988
    local.get 0
    call $call_class_method_param
    drop
    local.get 0
    call $dealloc_array
    drop
    i32.const 66673
    i32.const 66941
    i32.const 66312
    call $alloc_string
    local.tee 0
    call $call_class_method_1
    local.tee 1
    call $print_object
    drop
    local.get 1
    call $dealloc_object
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 66673
    i32.const 66396
    call $call_class_method_0
    local.tee 0
    call $print_object
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 66673
    call $alloc_objc_class
    i32.const 65731
    call $call_instance_method_0
    local.tee 0
    call $print_object
    drop
    local.get 0
    i32.const 66354
    call $call_instance_method_0
    local.tee 1
    call $print_object
    drop
    local.get 1
    call $dealloc_object
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 0)
  (memory (;0;) 2)
  (global $__stack_pointer (mut i32) (i32.const 65536))
  (global (;1;) i32 (i32.const 65536))
  (global (;2;) i32 (i32.const 67026))
  (global (;3;) i32 (i32.const 0))
  (global (;4;) i32 (i32.const 65536))
  (global (;5;) i32 (i32.const 65536))
  (global (;6;) i32 (i32.const 67040))
  (global (;7;) i32 (i32.const 131072))
  (global (;8;) i32 (i32.const 0))
  (global (;9;) i32 (i32.const 1))
  (global (;10;) i32 (i32.const 65536))
  (export "memory" (memory 0))
  (export "__wasm_call_ctors" (func $__wasm_call_ctors))
  (export "__stack_pointer" (global $__stack_pointer))
  (export "my_class_ReplaceMe_request" (func $my_class_ReplaceMe_request))
  (export "my_class_ReplaceMe_requestfromto" (func $my_class_ReplaceMe_requestfromto))
  (export "my_instance_ReplaceMe_request" (func $my_instance_ReplaceMe_request))
  (export "my_instance_ReplaceMe_requestfromto" (func $my_instance_ReplaceMe_requestfromto))
  (export "my_class_ReplaceMe_classtoken" (func $my_class_ReplaceMe_classtoken))
  (export "my_class_ReplaceMe_classmagicnumber" (func $my_class_ReplaceMe_classmagicnumber))
  (export "my_class_ReplaceMe_classfeatureenabled" (func $my_class_ReplaceMe_classfeatureenabled))
  (export "my_class_ReplaceMe_classscore" (func $my_class_ReplaceMe_classscore))
  (export "my_class_ReplaceMe_classcstring" (func $my_class_ReplaceMe_classcstring))
  (export "my_instance_ReplaceMe_instancetoken" (func $my_instance_ReplaceMe_instancetoken))
  (export "my_instance_ReplaceMe_instancemagicnumber" (func $my_instance_ReplaceMe_instancemagicnumber))
  (export "my_instance_ReplaceMe_instancefeatureenabled" (func $my_instance_ReplaceMe_instancefeatureenabled))
  (export "my_instance_ReplaceMe_instancescore" (func $my_instance_ReplaceMe_instancescore))
  (export "my_instance_ReplaceMe_instancecstring" (func $my_instance_ReplaceMe_instancecstring))
  (export "my_class_ReplaceMe_classbounds" (func $my_class_ReplaceMe_classbounds))
  (export "my_instance_ReplaceMe_sumofrect" (func $my_instance_ReplaceMe_sumofrect))
  (export "my_instance_ReplaceMe_fetch" (func $my_instance_ReplaceMe_fetch))
  (export "my_created_block" (func $my_created_block))
  (export "my_instance_ReplaceMe_sumtriple" (func $my_instance_ReplaceMe_sumtriple))
  (export "my_class_ReplaceMe_buildtriple" (func $my_class_ReplaceMe_buildtriple))
  (export "entry" (func $entry))
  (export "__dso_handle" (global 1))
  (export "__data_end" (global 2))
  (export "__stack_low" (global 3))
  (export "__stack_high" (global 4))
  (export "__global_base" (global 5))
  (export "__heap_base" (global 6))
  (export "__heap_end" (global 7))
  (export "__memory_base" (global 8))
  (export "__table_base" (global 9))
  (export "__wasm_first_page_end" (global 10))
  (data $.rodata (i32.const 65536) "{WAPTriple=idq}\00I am happy\00WebAssembly\00How are you today\00hello matrix\00my_class_ReplaceMe_request\00my_instance_ReplaceMe_request\00replaced - ReplaceMe request\00replaced + ReplaceMe request\00excellent\00init\00my_instance_ReplaceMe_sumofrect\00my_class_ReplaceMe_classbounds\00classBounds\00my_class_ReplaceMe_classmagicnumber\00my_instance_ReplaceMe_instancemagicnumber\00classMagicNumber\00instanceMagicNumber\00my_class_ReplaceMe_requestfromto\00my_instance_ReplaceMe_requestfromto\00my_class_ReplaceMe_classtoken\00my_instance_ReplaceMe_instancetoken\00replaced-class-token\00replaced-instance-token\00classToken\00instanceToken\00I am from c program\00my_created_block\00from-wasm-block\00sayHi\00my_instance_ReplaceMe_fetch\00my_class_ReplaceMe_classcstring\00my_instance_ReplaceMe_instancecstring\00replaced-class-c-string\00hello-c-string\00replaced-instance-c-string\00returnString\00classCString\00instanceCString\00staticCString\00 morning\00my_class_ReplaceMe_classscore\00my_instance_ReplaceMe_instancescore\00classScore\00instanceScore\00replaced - ReplaceMe requestFrom:Two to:One\00replaced + ReplaceMe requestFrom:Two to:One\00my_instance_ReplaceMe_sumtriple\00my_class_ReplaceMe_buildtriple\00buildTriple\00CallMe\00ReplaceMe\00good\00my_class_ReplaceMe_classfeatureenabled\00my_instance_ReplaceMe_instancefeatureenabled\00classFeatureEnabled\00instanceFeatureEnabled\00v@?@\00recordBlockResult:\00sumOfRect:\00doubleRect:\00requestFrom:to:\00registerCompletion:\00fetchWithCompletion:\00recordX:y:w:h:\00echoCString:\00sumTriple:\00sayYou:andMe:\00sayWord:\00callWithManyArguments:p1:p2:p3:p4:p5:\00"))

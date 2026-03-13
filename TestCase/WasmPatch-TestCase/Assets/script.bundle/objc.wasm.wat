(module $objc.wasm
  (type (;0;) (func (param i32) (result i32)))
  (type (;1;) (func (param i32) (result i64)))
  (type (;2;) (func (param i32 i32) (result i64)))
  (type (;3;) (func (param i32 i32 i64) (result i64)))
  (type (;4;) (func (param i64) (result i32)))
  (type (;5;) (func (param i32 i32 i64 i64) (result i64)))
  (type (;6;) (func (param i64 i32) (result i64)))
  (type (;7;) (func (param i64 i32 i64) (result i64)))
  (type (;8;) (func (param i64 i32 i64 i64) (result i64)))
  (type (;9;) (func (param i32 i32 i32) (result i32)))
  (type (;10;) (func (result i64)))
  (type (;11;) (func (param i64 i64) (result i32)))
  (type (;12;) (func (param i64) (result i64)))
  (type (;13;) (func (param f32) (result i64)))
  (type (;14;) (func (param f64) (result i64)))
  (type (;15;) (func))
  (type (;16;) (func (param i64 i32) (result i32)))
  (type (;17;) (func (param i64 i32 i64) (result i32)))
  (type (;18;) (func (param i64 i32) (result f64)))
  (type (;19;) (func (result i32)))
  (import "env" "print_string" (func $print_string (type 0)))
  (import "env" "new_objc_nsstring" (func $new_objc_nsstring (type 1)))
  (import "env" "alloc_string" (func $alloc_string (type 1)))
  (import "env" "call_class_method_0" (func $call_class_method_0 (type 2)))
  (import "env" "call_class_method_1" (func $call_class_method_1 (type 3)))
  (import "env" "dealloc_object" (func $dealloc_object (type 4)))
  (import "env" "call_class_method_2" (func $call_class_method_2 (type 5)))
  (import "env" "alloc_objc_class" (func $alloc_objc_class (type 1)))
  (import "env" "call_instance_method_0" (func $call_instance_method_0 (type 6)))
  (import "env" "call_instance_method_1" (func $call_instance_method_1 (type 7)))
  (import "env" "call_instance_method_2" (func $call_instance_method_2 (type 8)))
  (import "env" "replace_class_method" (func $replace_class_method (type 9)))
  (import "env" "replace_instance_method" (func $replace_instance_method (type 9)))
  (import "env" "print_object" (func $print_object (type 4)))
  (import "env" "new_objc_nsnumber_int" (func $new_objc_nsnumber_int (type 1)))
  (import "env" "alloc_array" (func $alloc_array (type 10)))
  (import "env" "append_array" (func $append_array (type 11)))
  (import "env" "alloc_int32" (func $alloc_int32 (type 1)))
  (import "env" "alloc_int64" (func $alloc_int64 (type 12)))
  (import "env" "alloc_float" (func $alloc_float (type 13)))
  (import "env" "alloc_double" (func $alloc_double (type 14)))
  (import "env" "call_class_method_param" (func $call_class_method_param (type 3)))
  (import "env" "dealloc_array" (func $dealloc_array (type 4)))
  (func $__wasm_call_ctors (type 15))
  (func $my_class_ReplaceMe_request (type 16) (param i64 i32) (result i32)
    i32.const 1164
    call $print_string
    drop
    i32.const 0)
  (func $my_class_ReplaceMe_requestfromto (type 17) (param i64 i32 i64) (result i32)
    i32.const 1890
    call $print_string
    drop
    i32.const 0)
  (func $my_instance_ReplaceMe_request (type 16) (param i64 i32) (result i32)
    i32.const 1135
    call $print_string
    drop
    i32.const 0)
  (func $my_instance_ReplaceMe_requestfromto (type 17) (param i64 i32 i64) (result i32)
    i32.const 1846
    call $print_string
    drop
    i32.const 0)
  (func $my_class_ReplaceMe_classtoken (type 6) (param i64 i32) (result i64)
    i32.const 1458
    call $new_objc_nsstring)
  (func $my_class_ReplaceMe_classmagicnumber (type 16) (param i64 i32) (result i32)
    i32.const 42)
  (func $my_class_ReplaceMe_classfeatureenabled (type 16) (param i64 i32) (result i32)
    i32.const 1)
  (func $my_class_ReplaceMe_classscore (type 18) (param i64 i32) (result f64)
    f64.const 0x1.3p+3 (;=9.5;))
  (func $my_class_ReplaceMe_classcstring (type 6) (param i64 i32) (result i64)
    i32.const 1624
    call $alloc_string)
  (func $my_instance_ReplaceMe_instancetoken (type 6) (param i64 i32) (result i64)
    i32.const 1479
    call $new_objc_nsstring)
  (func $my_instance_ReplaceMe_instancemagicnumber (type 16) (param i64 i32) (result i32)
    i32.const 43)
  (func $my_instance_ReplaceMe_instancefeatureenabled (type 16) (param i64 i32) (result i32)
    i32.const 1)
  (func $my_instance_ReplaceMe_instancescore (type 18) (param i64 i32) (result f64)
    f64.const 0x1.18p+3 (;=8.75;))
  (func $my_instance_ReplaceMe_instancecstring (type 6) (param i64 i32) (result i64)
    i32.const 1663
    call $alloc_string)
  (func $entry (type 19) (result i32)
    (local i64 i64 i64)
    i32.const 1934
    i32.const 1548
    call $call_class_method_0
    drop
    i32.const 1934
    i32.const 2126
    i32.const 1528
    call $new_objc_nsstring
    local.tee 0
    call $call_class_method_1
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 1934
    i32.const 2112
    i32.const 1047
    call $new_objc_nsstring
    local.tee 0
    i32.const 1024
    call $new_objc_nsstring
    local.tee 1
    call $call_class_method_2
    drop
    local.get 0
    call $dealloc_object
    drop
    local.get 1
    call $dealloc_object
    drop
    i32.const 1934
    call $alloc_objc_class
    local.tee 0
    i32.const 1548
    call $call_instance_method_0
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 1934
    call $alloc_objc_class
    local.tee 0
    i32.const 2126
    i32.const 1528
    call $new_objc_nsstring
    local.tee 1
    call $call_instance_method_1
    drop
    local.get 1
    call $dealloc_object
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 1934
    call $alloc_objc_class
    local.tee 0
    i32.const 2112
    i32.const 1047
    call $new_objc_nsstring
    local.tee 1
    i32.const 1024
    call $new_objc_nsstring
    local.tee 2
    call $call_instance_method_2
    drop
    local.get 1
    call $dealloc_object
    drop
    local.get 2
    call $dealloc_object
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 1941
    i32.const 1185
    i32.const 1078
    call $replace_class_method
    drop
    i32.const 1941
    i32.const 2083
    i32.const 1323
    call $replace_class_method
    drop
    i32.const 1941
    i32.const 1503
    i32.const 1392
    call $replace_class_method
    drop
    i32.const 1941
    i32.const 1286
    i32.const 1208
    call $replace_class_method
    drop
    i32.const 1941
    i32.const 2040
    i32.const 1956
    call $replace_class_method
    drop
    i32.const 1941
    i32.const 1821
    i32.const 1755
    call $replace_class_method
    drop
    i32.const 1941
    i32.const 1703
    i32.const 1554
    call $replace_class_method
    drop
    i32.const 1941
    i32.const 1185
    i32.const 1105
    call $replace_instance_method
    drop
    i32.const 1941
    i32.const 2083
    i32.const 1356
    call $replace_instance_method
    drop
    i32.const 1941
    i32.const 1514
    i32.const 1422
    call $replace_instance_method
    drop
    i32.const 1941
    i32.const 1303
    i32.const 1244
    call $replace_instance_method
    drop
    i32.const 1941
    i32.const 2060
    i32.const 1995
    call $replace_instance_method
    drop
    i32.const 1941
    i32.const 1832
    i32.const 1785
    call $replace_instance_method
    drop
    i32.const 1941
    i32.const 1716
    i32.const 1586
    call $replace_instance_method
    drop
    i32.const 1065
    call $print_string
    drop
    i32.const 1951
    call $new_objc_nsstring
    local.set 0
    i32.const 1746
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
    i32.const 1193
    call $new_objc_nsstring
    call $append_array
    drop
    local.get 0
    i32.const 1035
    call $alloc_string
    call $append_array
    drop
    i32.const 1934
    i32.const 2135
    local.get 0
    call $call_class_method_param
    drop
    local.get 0
    call $dealloc_array
    drop
    i32.const 1934
    i32.const 2099
    i32.const 1648
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
    i32.const 1934
    i32.const 1732
    call $call_class_method_0
    local.tee 0
    call $print_object
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 1934
    call $alloc_objc_class
    i32.const 1203
    call $call_instance_method_0
    local.tee 0
    call $print_object
    drop
    local.get 0
    i32.const 1690
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
  (global $__stack_pointer (mut i32) (i32.const 67712))
  (global (;1;) i32 (i32.const 1024))
  (global (;2;) i32 (i32.const 2173))
  (global (;3;) i32 (i32.const 2176))
  (global (;4;) i32 (i32.const 67712))
  (global (;5;) i32 (i32.const 1024))
  (global (;6;) i32 (i32.const 67712))
  (global (;7;) i32 (i32.const 131072))
  (global (;8;) i32 (i32.const 0))
  (global (;9;) i32 (i32.const 1))
  (export "memory" (memory 0))
  (export "__wasm_call_ctors" (func $__wasm_call_ctors))
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
  (data $.rodata (i32.const 1024) "I am happy\00WebAssembly\00How are you today\00hello matrix\00my_class_ReplaceMe_request\00my_instance_ReplaceMe_request\00replaced - ReplaceMe request\00replaced + ReplaceMe request\00excellent\00init\00my_class_ReplaceMe_classmagicnumber\00my_instance_ReplaceMe_instancemagicnumber\00classMagicNumber\00instanceMagicNumber\00my_class_ReplaceMe_requestfromto\00my_instance_ReplaceMe_requestfromto\00my_class_ReplaceMe_classtoken\00my_instance_ReplaceMe_instancetoken\00replaced-class-token\00replaced-instance-token\00classToken\00instanceToken\00I am from c program\00sayHi\00my_class_ReplaceMe_classcstring\00my_instance_ReplaceMe_instancecstring\00replaced-class-c-string\00hello-c-string\00replaced-instance-c-string\00returnString\00classCString\00instanceCString\00staticCString\00 morning\00my_class_ReplaceMe_classscore\00my_instance_ReplaceMe_instancescore\00classScore\00instanceScore\00replaced - ReplaceMe requestFrom:Two to:One\00replaced + ReplaceMe requestFrom:Two to:One\00CallMe\00ReplaceMe\00good\00my_class_ReplaceMe_classfeatureenabled\00my_instance_ReplaceMe_instancefeatureenabled\00classFeatureEnabled\00instanceFeatureEnabled\00requestFrom:to:\00echoCString:\00sayYou:andMe:\00sayWord:\00callWithManyArguments:p1:p2:p3:p4:p5:\00"))

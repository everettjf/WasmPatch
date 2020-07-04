(module
  (type (;0;) (func (param i32) (result i32)))
  (type (;1;) (func (param i32 i32) (result i64)))
  (type (;2;) (func (param i32) (result i64)))
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
  (type (;18;) (func (result i32)))
  (import "env" "print_string" (func $print_string (type 0)))
  (import "env" "call_class_method_0" (func $call_class_method_0 (type 1)))
  (import "env" "new_objc_nsstring" (func $new_objc_nsstring (type 2)))
  (import "env" "call_class_method_1" (func $call_class_method_1 (type 3)))
  (import "env" "dealloc_object" (func $dealloc_object (type 4)))
  (import "env" "call_class_method_2" (func $call_class_method_2 (type 5)))
  (import "env" "alloc_objc_class" (func $alloc_objc_class (type 2)))
  (import "env" "call_instance_method_0" (func $call_instance_method_0 (type 6)))
  (import "env" "call_instance_method_1" (func $call_instance_method_1 (type 7)))
  (import "env" "call_instance_method_2" (func $call_instance_method_2 (type 8)))
  (import "env" "replace_class_method" (func $replace_class_method (type 9)))
  (import "env" "replace_instance_method" (func $replace_instance_method (type 9)))
  (import "env" "print_object" (func $print_object (type 4)))
  (import "env" "new_objc_nsnumber_int" (func $new_objc_nsnumber_int (type 2)))
  (import "env" "alloc_array" (func $alloc_array (type 10)))
  (import "env" "append_array" (func $append_array (type 11)))
  (import "env" "alloc_int32" (func $alloc_int32 (type 2)))
  (import "env" "alloc_int64" (func $alloc_int64 (type 12)))
  (import "env" "alloc_float" (func $alloc_float (type 13)))
  (import "env" "alloc_double" (func $alloc_double (type 14)))
  (import "env" "alloc_string" (func $alloc_string (type 2)))
  (import "env" "call_class_method_param" (func $call_class_method_param (type 3)))
  (import "env" "dealloc_array" (func $dealloc_array (type 4)))
  (func $__wasm_call_ctors (type 15))
  (func $my_class_ReplaceMe_request (type 16) (param i64 i32) (result i32)
    i32.const 1024
    call $print_string
    drop
    i32.const 0)
  (func $my_class_ReplaceMe_requestfromto (type 17) (param i64 i32 i64) (result i32)
    i32.const 1053
    call $print_string
    drop
    i32.const 0)
  (func $my_instance_ReplaceMe_request (type 16) (param i64 i32) (result i32)
    i32.const 1097
    call $print_string
    drop
    i32.const 0)
  (func $my_instance_ReplaceMe_requestfromto (type 17) (param i64 i32 i64) (result i32)
    i32.const 1126
    call $print_string
    drop
    i32.const 0)
  (func $entry (type 18) (result i32)
    (local i64 i64 i64)
    i32.const 1170
    i32.const 1177
    call $call_class_method_0
    drop
    i32.const 1170
    i32.const 1203
    i32.const 1183
    call $new_objc_nsstring
    local.tee 0
    call $call_class_method_1
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 1170
    i32.const 1241
    i32.const 1212
    call $new_objc_nsstring
    local.tee 0
    i32.const 1230
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
    i32.const 1170
    call $alloc_objc_class
    local.tee 0
    i32.const 1177
    call $call_instance_method_0
    drop
    local.get 0
    call $dealloc_object
    drop
    i32.const 1170
    call $alloc_objc_class
    local.tee 0
    i32.const 1203
    i32.const 1183
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
    i32.const 1170
    call $alloc_objc_class
    local.tee 0
    i32.const 1241
    i32.const 1212
    call $new_objc_nsstring
    local.tee 1
    i32.const 1230
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
    i32.const 1255
    i32.const 1265
    i32.const 1273
    call $replace_class_method
    drop
    i32.const 1255
    i32.const 1300
    i32.const 1316
    call $replace_class_method
    drop
    i32.const 1255
    i32.const 1265
    i32.const 1349
    call $replace_instance_method
    drop
    i32.const 1255
    i32.const 1300
    i32.const 1379
    call $replace_instance_method
    drop
    i32.const 1415
    call $print_string
    drop
    i32.const 1428
    call $new_objc_nsstring
    local.set 0
    i32.const 1433
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
    i32.const 1442
    call $new_objc_nsstring
    call $append_array
    drop
    local.get 0
    i32.const 1452
    call $alloc_string
    call $append_array
    drop
    i32.const 1170
    i32.const 1464
    local.get 0
    call $call_class_method_param
    drop
    local.get 0
    call $dealloc_array
    drop
    i32.const 1170
    call $alloc_objc_class
    i32.const 1502
    call $call_instance_method_0
    local.tee 0
    call $print_object
    drop
    local.get 0
    i32.const 1507
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
  (table (;0;) 1 1 funcref)
  (memory (;0;) 2)
  (global (;0;) (mut i32) (i32.const 67056))
  (global (;1;) i32 (i32.const 1024))
  (global (;2;) i32 (i32.const 1520))
  (global (;3;) i32 (i32.const 1024))
  (global (;4;) i32 (i32.const 67056))
  (export "memory" (memory 0))
  (export "__wasm_call_ctors" (func $__wasm_call_ctors))
  (export "my_class_ReplaceMe_request" (func $my_class_ReplaceMe_request))
  (export "my_class_ReplaceMe_requestfromto" (func $my_class_ReplaceMe_requestfromto))
  (export "my_instance_ReplaceMe_request" (func $my_instance_ReplaceMe_request))
  (export "my_instance_ReplaceMe_requestfromto" (func $my_instance_ReplaceMe_requestfromto))
  (export "entry" (func $entry))
  (export "__dso_handle" (global 1))
  (export "__data_end" (global 2))
  (export "__global_base" (global 3))
  (export "__heap_base" (global 4))
  (data (;0;) (i32.const 1024) "replaced + ReplaceMe request\00replaced + ReplaceMe requestFrom:Two to:One\00replaced - ReplaceMe request\00replaced - ReplaceMe requestFrom:Two to:One\00CallMe\00sayHi\00I am from c program\00sayWord:\00How are you today\00I am happy\00sayYou:andMe:\00ReplaceMe\00request\00my_class_ReplaceMe_request\00requestFrom:to:\00my_class_ReplaceMe_requestfromto\00my_instance_ReplaceMe_request\00my_instance_ReplaceMe_requestfromto\00hello matrix\00good\00 morning\00excellent\00WebAssembly\00callWithManyArguments:p1:p2:p3:p4:p5:\00init\00returnString\00"))

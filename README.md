# WasmPatch

*Yet Another Patch Module For iOS/macOS* 

[![GitHub issues](https://img.shields.io/github/issues-raw/everettjf/WasmPatch?style=flat-square&label=issues&color=success)](https://github.com/everettjf/WasmPatch/issues) 
[![GitHub license](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](https://github.com/everettjf/WasmPatch)


WasmPatch bridges `Objective-C and WebAssembly`. We `build C code into WebAssembly`, and have the ability to `call any Objective-C class and method dynamically`. This makes the App obtaining the power of WebAssembly: add features or replacing Objective-C code to fix bugs dynamically.

WasmPatch is a **DEMO** now, and is still in development, welcome to improve the project together.

[![Twitter](https://img.shields.io/twitter/follow/everettjf?style=flat-square&color=1da1f2&label=twitter&logo=twitter)](https://twitter.com/everettjf) 
[![Discord](https://img.shields.io/discord/728632973670219870?style=flat-square&logo=discord&color=7289da&label=discord)](https://discord.gg/7qWjfzj)
[![Telegram](https://img.shields.io/badge/telegram-chat-0088cc?style=flat-square&logo=telegram)](https://t.me/wasmpatch)

## How it work

![WasmPatch](Image/WasmPatch.png)

<img align="right" width="311" height="118" src="/Image/wechat.png">

- 中文介绍: 请关注微信订阅号「首先很有趣」，点击菜单「专辑」查看「WasmPatch探索之路」专辑。
- English Introduction : TODO.

## Example

[View Source Directly](https://github.com/everettjf/WasmPatch/blob/master/TestCase/WasmPatch-TestCase/Assets/script.bundle/objc.c)

### Call Method

```
// method call - class method
call_class_method_0("CallMe", "sayHi");
    
WAPObject word = new_objc_nsstring("I am from c program");
call_class_method_1("CallMe", "sayWord:", word);
dealloc_object(word);

// method call - instance method
WAPObject call = alloc_objc_class("CallMe");
call_instance_method_0(call,"sayHi");
dealloc_object(call);

WAPObject call1 = alloc_objc_class("CallMe");
word = new_objc_nsstring("I am from c program");
call_instance_method_1(call1,"sayWord:", word);
dealloc_object(word);
dealloc_object(call1);
```

### Replace Method

```

int my_class_ReplaceMe_request(WAPObject self, const char * cmd) {
    print_string("replaced + ReplaceMe request");
    return 0;
}

int my_class_ReplaceMe_requestfromto(WAPObject self, const char * cmd, WAPArray parameters) {
    print_string("replaced + ReplaceMe requestFrom:Two to:One");
    return 0;
}
int my_instance_ReplaceMe_request(WAPObject self, const char * cmd) {
    print_string("replaced - ReplaceMe request");
    return 0;
}

int my_instance_ReplaceMe_requestfromto(WAPObject self, const char * cmd, WAPArray parameters) {
    print_string("replaced - ReplaceMe requestFrom:Two to:One");
    return 0;
}

int entry() {
    // method replace
    replace_class_method("ReplaceMe", "request", "my_class_ReplaceMe_request");
    replace_class_method("ReplaceMe", "requestFrom:to:", "my_class_ReplaceMe_requestfromto");

    replace_instance_method("ReplaceMe", "request", "my_instance_ReplaceMe_request");
    replace_instance_method("ReplaceMe", "requestFrom:to:", "my_instance_ReplaceMe_requestfromto");
}
```

### Call with many arguments

```
// many arguments
WAPArray params = alloc_array();
append_array(params, alloc_int32(10));
append_array(params, alloc_int64(666));
append_array(params, alloc_float(7.77));
append_array(params, alloc_double(200.2222));
append_array(params, new_objc_nsstring("excellent"));
append_array(params, alloc_string("WebAssembly"));
call_class_method_param("CallMe", "callWithManyArguments:p1:p2:p3:p4:p5:", params);
dealloc_array(params);
```

### Environment

- iOS/macOS.
- Tested: arm64/arm64e/x86_64 , Should work: armv7/armv7s/i386.
- C++17 standard.

## Quick playing with Demo

```
cd Demo && sh podinstall_all.sh
```

- iOS demo: open `Demo/WasmPatch-iOS/WasmPatch-iOS.xcworkspace`
- macOS demo: open `Demo/WasmPatch-macOS/WasmPatch-macOS.xcworkspace`

## Usage

### Build C into WebAssembly

To build c code into WebAssembly, we need to install llvm.

```
brew update
brew install llvm
```

### Playing with Demo

Demo c code for patch building:

```
TestCase/WasmPatch-TestCase/Assets/script.bundle/objc.c
```

Run `compile-testcase.sh` to build it.

```
cd TestCase && sh compile-testcase.sh
```

It will call `Tool/c2wasm.sh` internal.

Then, `Pod install` iOS and macOS demo.

```
cd Demo && sh podinstall_all.sh
```

Open `Demo/WasmPatch-iOS/WasmPatch-iOS.xcworkspace` for iOS demo, or open `Demo/WasmPatch-macOS/WasmPatch-macOS.xcworkspace` for macOS demo.


### Build Patch

```
./Tool/c2wasm.sh input.c output.wasm
```

### Load Patch

```
// header file
#import <WasmPatch/WasmPatch.h>

// ...

// call wap_load_file to load wasm file
NSString *scriptPath = [scriptBundlePath stringByAppendingPathComponent:@"objc.wasm"];
bool result = wap_load_file(scriptPath.UTF8String);
if (!result) {
    NSLog(@"failed load file %@", scriptPath);
    return;
}
```


## Installation

### CocoaPods

```
// local pod
pod 'WasmPatch', :path => '../../'

// online pod
pod 'WasmPatch'
```

### Manual

Drag `WasmPatch` directory into project, and configure `Header Search Path` to `WasmPatch/Classes/wap/depend/libffi/include`



## Thanks

- wasm3 https://github.com/wasm3/wasm3
- libffi https://github.com/libffi/libffi
- JSPatch https://github.com/bang590/JSPatch


---

Wish you enjoy :)
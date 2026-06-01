---
title: "Installation & integration"
eyebrow: "Getting started"
description: "Add WasmPatch to your app with Swift Package Manager or CocoaPods, and set up the wasm toolchain."
---

WasmPatch ships as both a Swift Package and a CocoaPod. The runtime links
`Foundation`, `CoreGraphics`, and `Security` automatically.

## Swift Package Manager

Add the package and link the `WasmPatch` product:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/everettjf/WasmPatch.git", branch: "master"),
],
targets: [
    .target(name: "MyApp", dependencies: ["WasmPatch"]),
]
```

In Xcode: **File → Add Package Dependencies…**, enter the repo URL, and add the
`WasmPatch` library to your target. For a local checkout, use **Add Local…** and
point at the repo (this is how `Demo/WasmPatch-SwiftUI` references it via an
`XCLocalSwiftPackageReference`).

```swift
import WasmPatch
```

## CocoaPods

```ruby
# Podfile
pod 'WasmPatch'
```

For a local checkout:

```ruby
pod 'WasmPatch', :path => '../path/to/WasmPatch'
```

To `import WasmPatch` from **Swift** via CocoaPods, build the pod as a module:

```ruby
use_frameworks!
```

(Objective-C targets can import the headers directly without `use_frameworks!`.)

Then `pod install` and work from the generated `.xcworkspace`.

## Manual / dragging sources

If you add the sources to a target by hand, put the libffi headers on the
Header Search Paths:

```
$(SRCROOT)/WasmPatch/Classes/wap/depend/libffi/include
```

and build as C++17 with `libc++` (see the podspec's xcconfig).

## Author SDK header

Patches `#include <wasmpatch.h>` (`Tool/sdk/wasmpatch.h`). The build tooling
(`Tool/wasmpatch build`, `Tool/c2wasm.sh`) puts it on the include path
automatically — you don't vendor it into your app.

## Toolchain

Building patches needs a wasm-capable clang (Apple's `clang` can't target
`wasm32`):

```bash
brew install llvm wabt
Tool/wasmpatch doctor   # checks clang/wasm-ld/wasm2wat/SDK header
```

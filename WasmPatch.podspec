
Pod::Spec.new do |spec|

  spec.name         = "WasmPatch"
  spec.version      = "0.1.0"
  spec.summary      = "WebAssembly-driven hot patching for iOS and macOS Objective-C apps."

  spec.description  = <<-DESC
  WasmPatch bridges Objective-C and WebAssembly. It compiles patch logic into
  WebAssembly modules, loads them at runtime, and dynamically calls or replaces
  Objective-C methods for hot-fix and feature delivery scenarios.
                   DESC

  spec.homepage     = "https://github.com/everettjf/WasmPatch"
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  spec.license      = "MIT"
  # spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  spec.author             = { "everettjf" => "everettjf@live.com" }
  spec.ios.deployment_target = "10.0"
  spec.osx.deployment_target = "10.14"

  spec.source       = { :git => "https://github.com/everettjf/WasmPatch.git", :tag => "#{spec.version}" }


  spec.source_files  = "WasmPatch/Classes/**/*"
  spec.exclude_files = "WasmPatch/Classes/**/*.txt", "WasmPatch/Classes/**/CMakeLists.txt"
  spec.public_header_files = "WasmPatch/Classes/*.h"

  spec.library = 'c++'
  spec.xcconfig = {
       'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
       'CLANG_CXX_LIBRARY' => 'libc++'
  }

end


Pod::Spec.new do |spec|

  spec.name         = "WasmPatch"
  spec.version      = "0.0.1"
  spec.summary      = "Yet Another Patch Module For iOS/macOS."

  spec.description  = <<-DESC
  WasmPatch bridges `Objective-C and WebAssembly`. We `build C code into WebAssembly`, 
  and have the ability to `call any Objective-C class and method dynamically`. This 
  makes the App obtaining the power of WebAssembly: add features or replacing 
  Objective-C code to fix bugs dynamically.
                   DESC

  spec.homepage     = "https://github.com/everettjf/WasmPatch"
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  spec.license      = "MIT"
  # spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  spec.author             = { "everettjf" => "everettjf@live.com" }
  # spec.social_media_url   = "https://twitter.com/everettjf"

  spec.ios.deployment_target = "10.0"
  spec.osx.deployment_target = "10.14"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"


  spec.source       = { :git => "https://github.com/WasmPatch/WasmPatch.git", :tag => "#{spec.version}" }


  spec.source_files  = "WasmPatch/Classes/**/*"
  # spec.exclude_files = "Classes/Exclude"
  spec.public_header_files = "WasmPatch/Classes/WasmPatch.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # spec.resource  = "icon.png"
  # spec.resources = "Resources/*.png"

  # spec.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # spec.framework  = "SomeFramework"
  # spec.frameworks = "SomeFramework", "AnotherFramework"

  # spec.library   = "iconv"
  # spec.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # spec.requires_arc = true

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # spec.dependency "JSONKit", "~> 1.4"

  spec.library = 'c++'
  spec.xcconfig = {
       'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
       'CLANG_CXX_LIBRARY' => 'libc++'
  }

end

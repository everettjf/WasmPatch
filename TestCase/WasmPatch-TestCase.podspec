#
# Be sure to run `pod lib lint WasmPatch-TestCase.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guidespec.cocoapodspec.org/syntax/podspec.html
#

Pod::Spec.new do |spec|
  spec.name             = 'WasmPatch-TestCase'
  spec.version          = '0.1.0'
  spec.summary          = 'Regression fixtures for validating WasmPatch bridge and hook behavior.'

# This description is used to generate tags and improve search resultspec.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  spec.description      = <<-DESC
Regression fixtures, sample patches, and host classes used to validate the
WasmPatch Objective-C bridge, method replacement behavior, and wasm tooling.
                       DESC

  spec.homepage         = 'https://github.com/everettjf/WasmPatch'
  # spec.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  spec.license          = { :type => 'MIT', :file => 'LICENSE' }
  spec.author           = { 'everettjf@live.com' => 'everettjf@live.com' }
  spec.source           = { :git => 'https://github.com/everettjf/WasmPatch.git', :tag => spec.version.to_s }


  spec.ios.deployment_target = "10.0"
  spec.osx.deployment_target = "10.14"
  spec.source_files = 'WasmPatch-TestCase/Classes/**/*'
  
  spec.resource_bundles = {
    'WasmPatch-TestCase' => ['WasmPatch-TestCase/Assets/*.bundle']
  }

  spec.dependency 'WasmPatch'
end

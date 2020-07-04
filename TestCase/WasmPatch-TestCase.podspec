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
  spec.summary          = 'A short description of WasmPatch-TestCase.'

# This description is used to generate tags and improve search resultspec.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  spec.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  spec.homepage         = 'https://github.com/WasmPatch/WasmPatch/WasmPatch-TestCase'
  # spec.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  spec.license          = { :type => 'MIT', :file => 'LICENSE' }
  spec.author           = { 'everettjf@live.com' => 'everettjf@live.com' }
  spec.source           = { :git => 'https://github.com/WasmPatch/WasmPatch/WasmPatch-TestCase.git', :tag => spec.version.to_s }
  # spec.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'


  spec.ios.deployment_target = "10.0"
  spec.osx.deployment_target = "10.14"
  # spec.watchospec.deployment_target = "2.0"
  # spec.tvospec.deployment_target = "9.0"

  spec.source_files = 'WasmPatch-TestCase/Classes/**/*'
  
  spec.resource_bundles = {
    'WasmPatch-TestCase' => ['WasmPatch-TestCase/Assets/*.bundle']
  }

  # spec.public_header_files = 'Pod/Classes/**/*.h'
  # spec.frameworks = 'UIKit', 'MapKit'
  spec.dependency 'WasmPatch'
end

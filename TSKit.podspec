#
# Be sure to run `pod lib lint TSKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guidespec.cocoapodspec.org/syntax/podspec.html
#

Pod::Spec.new do |spec|
  spec.name             = 'TSKit'
  spec.version          = '0.1.0'
  spec.summary          = 'An iOS TeamSpeak client'

  spec.description      = <<-DESC
  TSKit is a Objective-C wrapper around the C TeamSpeak client library.
                       DESC

  spec.homepage         = 'https://github.com/JanC/TSKit'
  spec.license          = { :type => 'MIT', :file => 'LICENSE' }
  spec.author           = { 'Jan Chaloupecky' => 'jan.chaloupecky@gmail.com' }
  spec.source           = { :git => 'https://github.com/JanC/TSKit.git', :tag => spec.version.to_s }
  
  spec.ios.deployment_target = '8.0'

  spec.frameworks = 'AVFoundation', 'AudioToolbox'

  spec.source_files = 'TSKit/Classes/**/*'
  
  spec.ios.vendored_library = 'TSKit/lib/libts3client.a'
  spec.libraries            = "ts3client", 'c++'

  spec.preserve_paths = 'TSKit/include/**' 
  
  # spec.header_dir          = "TSKit/include"
  # spec.header_mappings_dir = 'TSKit/include'

  spec.pod_target_xcconfig  =  {"HEADER_SEARCH_PATHS" => "$(PODS_ROOT)/#{spec.name}/include/**"}

end

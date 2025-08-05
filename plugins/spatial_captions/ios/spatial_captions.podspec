#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint spatial_captions.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'spatial_captions'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter plugin for managing spatial captions in AR environments'
  s.description      = <<-DESC
A Flutter plugin for managing spatial captions in AR environments. Provides native iOS ARKit integration for positioning and animating captions in 3D space.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m,swift}'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  # Add frameworks needed for ARKit and SceneKit
  s.frameworks = 'ARKit', 'SceneKit', 'UIKit'
end
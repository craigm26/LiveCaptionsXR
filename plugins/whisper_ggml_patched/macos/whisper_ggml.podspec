Pod::Spec.new do |s|
  s.name             = 'whisper_ggml'
  s.version          = '1.0.0'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage         = 'https://github.com/sk3llo/whisper_ggml'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'www.antonkarpenko.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.xcconfig = {
      'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20',
  }
  s.library = 'c++'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
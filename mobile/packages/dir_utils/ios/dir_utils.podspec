Pod::Spec.new do |s|
  s.name             = 'dir_utils'
  s.version          = '1.0.0'
  s.summary          = 'Cross-platform directory utilities with persistent access support'
  s.description      = <<-DESC
Cross-platform directory utilities providing security-scoped bookmark support on iOS
for persistent file access to user-selected directories outside the app sandbox.
                       DESC
  s.homepage         = 'https://github.com/ente-io/ente'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ente' => 'support@ente.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end

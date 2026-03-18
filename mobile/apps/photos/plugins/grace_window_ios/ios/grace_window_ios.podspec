Pod::Spec.new do |s|
  s.name             = 'grace_window_ios'
  s.version          = '1.0.0'
  s.summary          = 'iOS background grace window plugin.'
  s.description      = <<-DESC
iOS background grace window plugin for Ente Photos.
                       DESC
  s.homepage         = 'https://github.com/ente-io/ente'
  s.license          = { :type => 'AGPL-3.0' }
  s.author           = { 'Ente' => 'contact@ente.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end

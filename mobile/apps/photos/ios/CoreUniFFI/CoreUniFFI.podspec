Pod::Spec.new do |s|
  s.name             = 'CoreUniFFI'
  s.version          = '0.1.0'
  s.summary          = 'Swift UniFFI bindings for rust/uniffi/core'
  s.description      = <<-DESC
Swift wrapper module for Ente rust/uniffi/core crypto APIs, packaged as a local CocoaPod.
  DESC
  s.homepage         = 'https://ente.io'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'Ente' => 'support@ente.io' }
  s.source           = { :path => '.' }

  s.platform         = :ios, '14.0'
  s.swift_version    = '5.0'
  s.module_name      = 'CoreUniFFI'

  s.prepare_command = <<-CMD
    set -euo pipefail

    IOS_ROOT="$(cd .. && pwd)"
    "$IOS_ROOT/scripts/build_core_uniffi_xcframework.sh"

    mkdir -p "$PWD/Sources" "$PWD/Binaries"
    cp "$IOS_ROOT/Runner/Generated/CoreUniFFI/core.swift" "$PWD/Sources/core.swift"
    rm -rf "$PWD/Binaries/CoreUniFFIFFI.xcframework"
    cp -R "$IOS_ROOT/Runner/Generated/CoreUniFFIFFI.xcframework" "$PWD/Binaries/CoreUniFFIFFI.xcframework"
  CMD

  s.source_files = 'Sources/**/*.swift'
  s.vendored_frameworks = 'Binaries/CoreUniFFIFFI.xcframework'
end

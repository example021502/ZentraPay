# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint privy_flutter.podspec` to validate before publishing.

Pod::Spec.new do |s|
  s.name             = 'privy_flutter'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter Plug in that enables direct integration with native Privy SDKs'
  s.description      = <<-DESC
Privy Flutter SDK enables seamless authentication, wallet management, and identity verification for Flutter apps with native iOS and Android support. 
                       DESC
  s.homepage         = 'http://privy.io'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :git => 'https://github.com/privy-io/flutter-sdk', :tag => s.version.to_s }
  s.source_files = 'privy_flutter/Sources/privy_flutter/**/*.{swift}'
  s.dependency       'Flutter'
  s.dependency       'PrivySDK', '2.12.0'
  s.dependency       'Factory', '2.4.3'
  s.platform         = :ios, '17.0'
  # Flutter.framework does not contain an i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'privy_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end

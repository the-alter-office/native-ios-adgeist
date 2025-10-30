Pod::Spec.new do |s|
  s.name             = 'AdgeistKit'
  s.version          = '0.0.10'
  s.summary          = 'AdGeist iOS SDK'
  s.description      = 'AdGeist tracking and attribution SDK for iOS apps'
  s.homepage         = 'https://github.com/the-alter-office/native-ios-adgeist'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = { 'kishore' => 'kishore@thealteroffice.com' }
  s.platform         = :ios, '11.0'
  s.source           = { :git => 'https://github.com/the-alter-office/native-ios-adgeist.git', :tag => "#{s.version}"}

  s.ios.deployment_target = '12.0'

  s.vendored_frameworks = 'output/AdgeistKit.xcframework'
  s.requires_arc = true

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
    'DEFINES_MODULE' => 'YES',
    'SWIFT_INSTALL_OBJC_HEADER' => 'YES',
  }

  s.swift_version = '5.0'
end 


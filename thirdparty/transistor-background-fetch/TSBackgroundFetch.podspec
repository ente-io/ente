#
# Be sure to run `pod lib lint TSBackgroundFetch.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TSBackgroundFetch'
  s.version          = '0.0.1'
  s.summary          = 'iOS Background Fetch API Manager'

  s.description      = <<-DESC
iOS Background Fetch API Manager with ability to handle multiple listeners.
                       DESC

  s.homepage         = 'http://www.transistorsoft.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'christocracy' => 'christocracy@gmail.com' }
  s.source           = { :git => 'https://github.com/transistorsoft/transistor-background-fetch.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/christocracy'

  s.ios.deployment_target = '8.0'

  s.source_files        = 'ios/TSBackgroundFetch/TSBackgroundFetch/*.{h,m}'
  s.vendored_frameworks = 'ios/TSBackgroundFetch/TSBackgroundFetch.framework'
end

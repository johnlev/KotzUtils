#
# Be sure to run `pod lib lint KotzUtils.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KotzUtils'
  s.version          = '0.1.1'
  s.summary          = 'A series of utilities prefered by myself usefull for making a Swift iOS app very quickly'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Contained in this Cocoapod are a bunch of tools I (John Kotz) find very usefull for creating Swift iOS apps quickly and efficiently. Feel free to use my code so your app can be more efficient and effective.
                       DESC

  s.homepage         = 'https://github.com/johnlev/KotzUtils'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'johnlev' => 'john.lyme@mac.com' }
  s.source           = { :git => 'https://github.com/johnlev/KotzUtils.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.source_files = 'KotzUtils/Classes/**/*'
  s.swift_version = '4.0'
  
  # s.resource_bundles = {
  #   'KotzUtils' => ['KotzUtils/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
   s.frameworks = 'UIKit'
   s.dependency 'FutureKit'
   s.dependency 'EmitterKit'
end

#
# Be sure to run `pod lib lint CombineAsync.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CombineAsync'
  s.version          = '1.3.0'
  s.summary          = 'Combine extensions and utilities for an async task'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  CombineAsync is Combine extensions and utilities for an async task
                       DESC

  s.homepage         = 'https://github.com/hainayanda/CombineAsync'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'hainayanda' => 'hainayanda@outlook.com' }
  s.source           = { :git => 'https://github.com/hainayanda/CombineAsync.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = "13.0"
  s.osx.deployment_target = "10.15"
  s.tvos.deployment_target = '13.0'
  s.watchos.deployment_target = '8.0'
  s.swift_versions = '5.5'

  s.source_files = 'CombineAsync/Classes/**/*'
  
  # s.resource_bundles = {
  #   'CombineAsync' => ['CombineAsync/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'Retain', '~> 1.0.1'
end

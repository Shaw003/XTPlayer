#
# Be sure to run `pod lib lint XTPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XTPlayer'
  s.version          = '0.2.1'
  s.summary          = '一款基于AVPlayer封装的音频播放器。'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Shaw003/XTPlayer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Shaw' => 'shawtun1211@163.com' }
  s.source           = { :git => 'https://github.com/Shaw003/XTPlayer', :tag => s.version.to_s }
  s.social_media_url = 'https://www.jianshu.com/u/596fa2382f62'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Pod/*.swift'

  
  # s.resource_bundles = {
  #   'XTPlayer' => ['XTPlayer/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Alamofire'
  s.dependency 'WCDB.swift', '1.0.7.5'
end

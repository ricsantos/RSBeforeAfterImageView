#
# Be sure to run `pod lib lint RSBeforeAfterImageView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RSBeforeAfterImageView'
  s.version          = '0.1.0'
  s.summary          = 'A UIView with two images and a draggable / animatable slider that masks the difference'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
You have two images, maybe one was edited, and you want to see the differerence. This class is for you.
Given two images, it puts one on top of the other, and provides a slider to slide the mask left and right.
                       DESC

  s.homepage         = 'https://github.com/ricsantos/RSBeforeAfterImageView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ric Santos' => 'rics@ntos.me' }
  s.source           = { :git => 'https://github.com/ricsantos/RSBeforeAfterImageView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '14.0'

  s.source_files = 'Pod/Classes/**/*'
  
  # s.resource_bundles = {
  #   'RSBeforeAfterImageView' => ['RSBeforeAfterImageView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

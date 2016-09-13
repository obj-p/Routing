Pod::Spec.new do |s|
  s.name             = "Routing"
  s.version          = "1.1.0"
  s.summary          = "A Swift router implementation"
  s.description      = <<-DESC
                        Routing allows for routing URLs matched by string patterns to associated closures.
                        DESC
  s.homepage         = "https://github.com/jwalapr/Routing"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Jason Prasad" => "jwalapr@gmail.com" }
  s.source           = { :git => "https://github.com/jwalapr/Routing.git", :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'  
  s.osx.deployment_target = '10.11'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.1'
  s.frameworks = 'Foundation'
  s.ios.framework = 'UIKit', 'QuartzCore'
  s.source_files = 'Source/Ro*.swift'
  s.ios.source_files = 'Source/iOS.swift'
end

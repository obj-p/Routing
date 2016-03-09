Pod::Spec.new do |s|
  s.name             = "Routing"
  s.version          = "0.2.0"
  s.summary          = "A swift router implementation"
  s.description      = <<-DESC
                        Routing allows for routing URLs matched by string patterns to associated closures.
                        DESC
  s.homepage         = "https://github.com/jwalapr/Routing"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Jason Prasad" => "jwalapr@gmail.com" }
  s.source           = { :git => "https://github.com/jwalapr/Routing.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.ios.deployment_target = '9.0'
  s.frameworks   = 'UIKit', 'QuartzCore'
  s.source_files = 'Source/Routing.swift', 'Source/RoutingiOS.swift'
end

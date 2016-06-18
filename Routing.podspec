Pod::Spec.new do |s|
  s.name             = "Routing"
  s.version          = "0.3.0"
  s.summary          = "A Swift router implementation"
  s.description      = <<-DESC
                        Routing allows for routing URLs matched by string patterns to associated closures.
                        DESC
  s.homepage         = "https://github.com/jwalapr/Routing"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Jason Prasad" => "jwalapr@gmail.com" }
  s.source           = { :git => "https://github.com/jwalapr/Routing.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.ios.deployment_target = '8.0'  

  s.subspec "iOS" do |sp|
    sp.framework   = 'UIKit', 'QuartzCore'
    sp.source_files = 'Source/Routing.swift', 'Source/RoutingiOS.swift', 'Source/Route.swift'
  end

  s.subspec "Others" do |sp|
    sp.osx.deployment_target = '10.11'
    sp.tvos.deployment_target = '9.0'
    sp.watchos.deployment_target = '2.1'
    sp.source_files = 'Source/Routing.swift', 'Source/Route.swift'
  end

  s.default_subspec = "iOS"
end

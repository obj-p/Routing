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
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.1'
  s.requires_arc = true
  s.source_files     = 'Source/*.swift'
  s.default_subspec = 'ios'

  s.subspec 'ios' do |sp|
    sp.module_name = 'UIKit'
    sp.source_files = 'Source/Routing.swift', 'Source/RoutingiOS.swift'
  end

  s.subspec 'other' do |sp|
    sp.source_files = 'Source/Routing.swift', 'Source/RoutingOthers.swift'
  end

end

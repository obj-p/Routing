Pod::Spec.new do |s|
  s.name             = "Routing"
  s.version          = "0.0.1"
  s.summary          = "Routing in Swift"
  s.description      = <<-DESC
                        Routing allows for routing URLs matched by string patterns to associated closures.
                        DESC
  s.homepage         = "https://github.com/jwalapr/Routing"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Jason Prasad" => "jwalapr@gmail.com" }
  s.source           = { :git => "https://github.com/jwalapr/Routing.git", :tag => s.version.to_s }
  s.ios.deployment_target     = '9.0'
  s.requires_arc = true
  s.source_files     = 'Source/*.swift'
end

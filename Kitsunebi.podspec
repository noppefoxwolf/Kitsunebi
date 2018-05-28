Pod::Spec.new do |s|
  s.name             = 'Kitsunebi'
  s.version          = '0.2.0'
  s.summary          = 'Overlay alpha channel video animation player view.'
  s.description      = <<-DESC
Overlay alpha channel video animation player view using OpenGLES.
                       DESC
  s.homepage         = 'https://github.com/noppefoxwolf/Kitsunebi'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tomoya Hirano' => 'noppelabs@gmail.com' }
  s.source           = { :git => 'https://github.com/noppefoxwolf/Kitsunebi.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/noppefoxwolf'
  s.ios.deployment_target = '9.0'
  s.source_files = 'Kitsunebi/Classes/**/*'
end

Pod::Spec.new do |s|
  s.name     = 'GPUImage-flow'
  s.version  = '0.1.11'
  s.license  = 'BSD'
  s.summary  = 'An open source iOS framework for GPU-based image and video processing.'
  s.homepage = 'https://github.com/luosch/GPUImage'
  s.author   = { 'lsc' => 'i@lsich.com' }
  s.source   = { :git => 'https://github.com/luosch/GPUImage.git', :tag => "#{s.version}-flow" }
  
  s.source_files = 'framework/Source/**/*.{h,m}'
  s.resources = 'framework/Resources/*.png'
  s.requires_arc = true
  s.xcconfig = { 'CLANG_MODULES_AUTOLINK' => 'YES' }
  
  s.platform = :ios, '5.0'
  s.ios.deployment_target = '5.0'
  s.ios.exclude_files = 'framework/Source/Mac'
  s.ios.frameworks   = ['OpenGLES', 'CoreMedia', 'QuartzCore', 'AVFoundation']

  s.module_name = "GPUImage"
end

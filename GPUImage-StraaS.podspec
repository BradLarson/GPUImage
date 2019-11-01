Pod::Spec.new do |s|
  s.name     = 'GPUImage-StraaS'
  s.version  = '0.1.8'
  s.license  = 'BSD'
  s.module_name   = 'GPUImage'
  s.summary  = 'An open source iOS framework for GPU-based image and video processing.'
  s.homepage = 'https://github.com/BradLarson/GPUImage'
  s.author   = { 'Brad Larson' => 'contact@sunsetlakesoftware.com' }
  s.source   = { :git => 'https://github.com/StraaS/GPUImage.git', :tag => "#{s.version}" }
  
  s.source_files = 'framework/Source/**/*.{h,m}'
  s.resources = 'framework/Resources/*.png'
  s.requires_arc = true
  s.xcconfig = { 'CLANG_MODULES_AUTOLINK' => 'YES' }
  
  s.ios.deployment_target = '5.0'
  s.ios.exclude_files = 'framework/Source/Mac'
  s.ios.frameworks   = ['OpenGLES', 'CoreMedia', 'QuartzCore', 'AVFoundation']
end

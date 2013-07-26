Pod::Spec.new do |s|
  s.name     = 'eGPUImage'
  s.version  = '0.1'
  s.license  = 'BSD'
  s.platform = :ios
  s.summary  = 'evfemist pause/resume fork'
  s.homepage = 'https://github.com/evfemist/GPUImage'
  s.author   = { 'Brad Larson' => 'contact@sunsetlakesoftware.com' }
  s.source   = { :git => 'https://github.com/evfemist/GPUImage.git', :branch => 'dev'}
  s.source_files = 'framework/Source/**/*.{h,m}'
  s.osx.exclude_files = 'framework/Source/iOS/**/*.{h,m}'
  s.ios.exclude_files = 'framework/Source/Mac/**/*.{h,m}'
  s.frameworks   = ['OpenGLES', 'CoreVideo', 'CoreMedia', 'QuartzCore', 'AVFoundation']

  s.requires_arc = true
end
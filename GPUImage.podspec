Pod::Spec.new do |s|
  s.name     = 'GPUImage'
  s.license  = 'BSD'
  s.version  = '0.1.0'
  s.summary  = 'An open source iOS framework for GPU-based image and video processing.'
  s.homepage = 'https://github.com/BradLarson/GPUImage'
  s.authors  = { 'Brad Larson' => 'contact@sunsetlakesoftware.com' }
  s.source   = { :git => 'https://github.com/BradLarson/GPUImage.git' }
  s.source_files = 'GPUImage'
  s.requires_arc = true

  s.ios.deployment_target = '5.0'
  s.ios.frameworks = 'CoreMedia', 'CoreVideo', 'OpenGLES', 'QuartzCore', 'AVFoundation'

  s.prefix_header_contents = <<-EOS
#ifdef __OBJC__
    #import <Foundation/Foundation.h>
#endif
EOS
end

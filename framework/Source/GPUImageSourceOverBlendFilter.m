#import "GPUImageSourceOverBlendFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageSourceOverBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
   lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
   lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
   
   gl_FragColor = mix(textureColor, textureColor2, textureColor2.a);
 }
);
#else
NSString *const kGPUImageSourceOverBlendFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
     
     gl_FragColor = mix(textureColor, textureColor2, textureColor2.a);
 }
 );
#endif

@implementation GPUImageSourceOverBlendFilter

- (id)init;
{
  if (!(self = [super initWithFragmentShaderFromString:kGPUImageSourceOverBlendFragmentShaderString]))
  {
		return nil;
  }
  
  return self;
}

@end

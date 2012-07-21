#import "GPUImageSourceOverBlendFilter.h"

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

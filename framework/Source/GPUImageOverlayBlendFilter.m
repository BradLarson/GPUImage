#import "GPUImageOverlayBlendFilter.h"

NSString *const kGPUImageOverlayBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     lowp vec4 base = texture2D(inputImageTexture, textureCoordinate);
     lowp vec4 overlay = texture2D(inputImageTexture2, textureCoordinate);
     gl_FragColor = vec4(
                         (base.r < 0.5 ? (2.0 * base.r * overlay.r) : (1.0 - 2.0 * (1.0 - base.r) * (1.0 - overlay.r))), 
                         (base.g < 0.5 ? (2.0 * base.g * overlay.g) : (1.0 - 2.0 * (1.0 - base.g) * (1.0 - overlay.g))), 
                         (base.b < 0.5 ? (2.0 * base.b * overlay.b) : (1.0 - 2.0 * (1.0 - base.b) * (1.0 - overlay.b))), 
                         1.0
                         );
 }
);

@implementation GPUImageOverlayBlendFilter

- (id)init;
{
  if (!(self = [super initWithFragmentShaderFromString:kGPUImageOverlayBlendFragmentShaderString]))
  {
		return nil;
  }
  
  return self;
}

@end


#import "GPUImageSoftLightBlendFilter.h"

NSString *const kGPUImageSoftLightBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
     gl_FragColor = 2.0 * textureColor2 * textureColor + textureColor * textureColor - 2.0 * textureColor * textureColor *textureColor2;
 }
);

@implementation GPUImageSoftLightBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSoftLightBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


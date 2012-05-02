#import "GPUImageLightenBlendFilter.h"

NSString *const kGPUImageLightenBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
    
    gl_FragColor = max(textureColor, textureColor2);
 }
);

@implementation GPUImageLightenBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageLightenBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


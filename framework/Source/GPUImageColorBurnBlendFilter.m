#import "GPUImageColorBurnBlendFilter.h"

NSString *const kGPUImageColorBurnBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
    mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
    mediump vec4 whiteColor = vec4(1.0);
    gl_FragColor = whiteColor - (whiteColor - textureColor) / textureColor2;
 }
);

@implementation GPUImageColorBurnBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageColorBurnBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


#import "GPUImageColorDodgeBlendFilter.h"

NSString *const kGPUImageColorDodgeBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
     mediump vec4 whiteColor = vec4(1.0);
     gl_FragColor = textureColor / (whiteColor - textureColor2);
 }
);

@implementation GPUImageColorDodgeBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageColorDodgeBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


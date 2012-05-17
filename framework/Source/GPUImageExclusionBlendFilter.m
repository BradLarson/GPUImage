#import "GPUImageExclusionBlendFilter.h"

NSString *const kGPUImageExclusionBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     gl_FragColor = vec4(textureColor.rgb + textureColor2.rgb - (2.0 * textureColor.rgb * textureColor2.rgb), textureColor.a);
 }
);

@implementation GPUImageExclusionBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageExclusionBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


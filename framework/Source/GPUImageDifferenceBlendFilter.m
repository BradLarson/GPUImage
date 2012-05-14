#import "GPUImageDifferenceBlendFilter.h"

NSString *const kGPUImageDifferenceBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     gl_FragColor = vec4(abs(textureColor2.rgb - textureColor.rgb), textureColor.a);
 }
);

@implementation GPUImageDifferenceBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageDifferenceBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


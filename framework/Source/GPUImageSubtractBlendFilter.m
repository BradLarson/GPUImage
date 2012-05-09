#import "GPUImageSubtractBlendFilter.h"

NSString *const kGPUImageSubtractBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
	 lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
	 lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
	 
	 gl_FragColor = vec4(textureColor.rgb - textureColor2.rgb, textureColor.a);
 }
 );

@implementation GPUImageSubtractBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSubtractBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


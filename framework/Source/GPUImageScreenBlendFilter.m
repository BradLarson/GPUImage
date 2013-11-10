#import "GPUImageScreenBlendFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageScreenBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     
     // premultiply RGB with alpha
     textureColor.rgb *= textureColor.a;
     textureColor2.rgb *= textureColor2.a;
     
     mediump vec4 textureOut = textureColor2 + textureColor - textureColor2 * textureColor;
     // factor out the resulting alpha from RGB
     textureOut.rgb /= textureOut.a;
     
     gl_FragColor = textureOut;
 }
);
#else
NSString *const kGPUImageScreenBlendFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     
     // premultiply RGB with alpha
     textureColor.rgb *= textureColor.a;
     textureColor2.rgb *= textureColor2.a;
     
     vec4 textureOut = textureColor2 + textureColor - textureColor2 * textureColor;
     // factor out the resulting alpha from RGB
     textureOut.rgb /= textureOut.a;
     
     gl_FragColor = textureOut;
 }
);
#endif

@implementation GPUImageScreenBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageScreenBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


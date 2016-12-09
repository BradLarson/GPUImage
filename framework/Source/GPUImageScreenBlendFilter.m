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
     mediump vec4 multipliedTextureColor = vec4(textureColor.rgb * textureColor.a, textureColor.a);
     mediump vec4 multipliedTextureColor2 = vec4(textureColor2.rgb * textureColor2.a, textureColor2.a);
     gl_FragColor = multipliedTextureColor2 + multipliedTextureColor - (multipliedTextureColor2 * multipliedTextureColor);
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
     vec4 multipliedTextureColor = vec4(textureColor.rgb * textureColor.a, textureColor.a);
     vec4 multipliedTextureColor2 = vec4(textureColor2.rgb * textureColor2.a, textureColor2.a);
     gl_FragColor = multipliedTextureColor2 + multipliedTextureColor - (multipliedTextureColor2 * multipliedTextureColor);
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


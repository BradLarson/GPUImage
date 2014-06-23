#import "GPUImageLinearBurnBlendFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageLinearBurnBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     
     gl_FragColor = vec4(clamp(textureColor.rgb + textureColor2.rgb - vec3(1.0), vec3(0.0), vec3(1.0)), textureColor.a);
 }
);
#else
NSString *const kGPUImageLinearBurnBlendFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     
     gl_FragColor = vec4(clamp(textureColor.rgb + textureColor2.rgb - vec3(1.0), vec3(0.0), vec3(1.0)), textureColor.a);
 }
);
#endif

@implementation GPUImageLinearBurnBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageLinearBurnBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end

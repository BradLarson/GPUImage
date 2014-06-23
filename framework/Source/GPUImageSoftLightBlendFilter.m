#import "GPUImageSoftLightBlendFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageSoftLightBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     mediump vec4 base = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
     
     lowp float alphaDivisor = base.a + step(base.a, 0.0); // Protect against a divide-by-zero blacking out things in the output
     gl_FragColor = base * (overlay.a * (base / alphaDivisor) + (2.0 * overlay * (1.0 - (base / alphaDivisor)))) + overlay * (1.0 - base.a) + base * (1.0 - overlay.a);
 }
);
#else
NSString *const kGPUImageSoftLightBlendFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 base = texture2D(inputImageTexture, textureCoordinate);
     vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
     
     float alphaDivisor = base.a + step(base.a, 0.0); // Protect against a divide-by-zero blacking out things in the output
     gl_FragColor = base * (overlay.a * (base / alphaDivisor) + (2.0 * overlay * (1.0 - (base / alphaDivisor)))) + overlay * (1.0 - base.a) + base * (1.0 - overlay.a);
 }
);
#endif

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


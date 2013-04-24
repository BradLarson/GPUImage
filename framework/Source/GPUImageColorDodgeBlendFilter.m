#import "GPUImageColorDodgeBlendFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageColorDodgeBlendFragmentShaderString = SHADER_STRING
( 
 
 precision mediump float;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 base = texture2D(inputImageTexture, textureCoordinate);
     vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
     
     vec3 baseOverlayAlphaProduct = vec3(overlay.a * base.a);
     vec3 rightHandProduct = overlay.rgb * (1.0 - base.a) + base.rgb * (1.0 - overlay.a);
     
     vec3 firstBlendColor = baseOverlayAlphaProduct + rightHandProduct;
     vec3 overlayRGB = clamp((overlay.rgb / clamp(overlay.a, 0.01, 1.0)) * step(0.0, overlay.a), 0.0, 0.99);
     
     vec3 secondBlendColor = (base.rgb * overlay.a) / (1.0 - overlayRGB) + rightHandProduct;
     
     vec3 colorChoice = step((overlay.rgb * base.a + base.rgb * overlay.a), baseOverlayAlphaProduct);
     
     gl_FragColor = vec4(mix(firstBlendColor, secondBlendColor, colorChoice), 1.0);
 }
);
#else
NSString *const kGPUImageColorDodgeBlendFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 base = texture2D(inputImageTexture, textureCoordinate);
     vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
     
     vec3 baseOverlayAlphaProduct = vec3(overlay.a * base.a);
     vec3 rightHandProduct = overlay.rgb * (1.0 - base.a) + base.rgb * (1.0 - overlay.a);
     
     vec3 firstBlendColor = baseOverlayAlphaProduct + rightHandProduct;
     vec3 overlayRGB = clamp((overlay.rgb / clamp(overlay.a, 0.01, 1.0)) * step(0.0, overlay.a), 0.0, 0.99);
     
     vec3 secondBlendColor = (base.rgb * overlay.a) / (1.0 - overlayRGB) + rightHandProduct;
     
     vec3 colorChoice = step((overlay.rgb * base.a + base.rgb * overlay.a), baseOverlayAlphaProduct);
     
     gl_FragColor = vec4(mix(firstBlendColor, secondBlendColor, colorChoice), 1.0);
 }
);
#endif

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


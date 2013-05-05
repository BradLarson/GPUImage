#import "GPUImageSingleComponentFastBlurFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageSingleComponentFastBlurFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 uniform sampler2D inputImageTexture;
 
 varying highp vec2 centerTextureCoordinate;
 varying highp vec2 oneStepLeftTextureCoordinate;
 varying highp vec2 twoStepsLeftTextureCoordinate;
 varying highp vec2 oneStepRightTextureCoordinate;
 varying highp vec2 twoStepsRightTextureCoordinate;
 
 // const float weight[3] = float[]( 0.2270270270, 0.3162162162, 0.0702702703 );
 
 void main()
 {
     lowp float fragmentColor = texture2D(inputImageTexture, centerTextureCoordinate).r * 0.2270270270;
     fragmentColor += texture2D(inputImageTexture, oneStepLeftTextureCoordinate).r * 0.3162162162;
     fragmentColor += texture2D(inputImageTexture, oneStepRightTextureCoordinate).r * 0.3162162162;
     fragmentColor += texture2D(inputImageTexture, twoStepsLeftTextureCoordinate).r * 0.0702702703;
     fragmentColor += texture2D(inputImageTexture, twoStepsRightTextureCoordinate).r * 0.0702702703;
     
     gl_FragColor = vec4(vec3(fragmentColor), 1.0);
 }
);
#else
NSString *const kGPUImageSingleComponentFastBlurFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepLeftTextureCoordinate;
 varying vec2 twoStepsLeftTextureCoordinate;
 varying vec2 oneStepRightTextureCoordinate;
 varying vec2 twoStepsRightTextureCoordinate;
 
 // const float weight[3] = float[]( 0.2270270270, 0.3162162162, 0.0702702703 );
 
 void main()
 {
     float fragmentColor = texture2D(inputImageTexture, centerTextureCoordinate).r * 0.2270270270;
     fragmentColor += texture2D(inputImageTexture, oneStepLeftTextureCoordinate).r * 0.3162162162;
     fragmentColor += texture2D(inputImageTexture, oneStepRightTextureCoordinate).r * 0.3162162162;
     fragmentColor += texture2D(inputImageTexture, twoStepsLeftTextureCoordinate).r * 0.0702702703;
     fragmentColor += texture2D(inputImageTexture, twoStepsRightTextureCoordinate).r * 0.0702702703;
     
     gl_FragColor = vec4(vec3(fragmentColor), 1.0);
 }
);
#endif

@implementation GPUImageSingleComponentFastBlurFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSingleComponentFastBlurFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end

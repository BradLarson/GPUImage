#import "GPUImageRGBDilationFilter.h"
#import "GPUImageDilationFilter.h"

// Radius 1
NSString *const kGPUImageRGBDilationRadiusOneFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepPositiveTextureCoordinate;
 varying vec2 oneStepNegativeTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     lowp vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
     lowp vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
     lowp vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
     
     lowp vec4 maxValue = max(centerIntensity, oneStepPositiveIntensity);
     
     gl_FragColor = max(maxValue, oneStepNegativeIntensity);
 }
);

// Radius 2
NSString *const kGPUImageRGBDilationRadiusTwoFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepPositiveTextureCoordinate;
 varying vec2 oneStepNegativeTextureCoordinate;
 varying vec2 twoStepsPositiveTextureCoordinate;
 varying vec2 twoStepsNegativeTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     lowp vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
     lowp vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
     lowp vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
     lowp vec4 twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate);
     lowp vec4 twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate);
     
     lowp vec4 maxValue = max(centerIntensity, oneStepPositiveIntensity);
     maxValue = max(maxValue, oneStepNegativeIntensity);
     maxValue = max(maxValue, twoStepsPositiveIntensity);
     maxValue = max(maxValue, twoStepsNegativeIntensity);
     
     gl_FragColor = max(maxValue, twoStepsNegativeIntensity);
 }
);

// Radius 3
NSString *const kGPUImageRGBDilationRadiusThreeFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepPositiveTextureCoordinate;
 varying vec2 oneStepNegativeTextureCoordinate;
 varying vec2 twoStepsPositiveTextureCoordinate;
 varying vec2 twoStepsNegativeTextureCoordinate;
 varying vec2 threeStepsPositiveTextureCoordinate;
 varying vec2 threeStepsNegativeTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     lowp vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
     lowp vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
     lowp vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
     lowp vec4 twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate);
     lowp vec4 twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate);
     lowp vec4 threeStepsPositiveIntensity = texture2D(inputImageTexture, threeStepsPositiveTextureCoordinate);
     lowp vec4 threeStepsNegativeIntensity = texture2D(inputImageTexture, threeStepsNegativeTextureCoordinate);
     
     lowp vec4 maxValue = max(centerIntensity, oneStepPositiveIntensity);
     maxValue = max(maxValue, oneStepNegativeIntensity);
     maxValue = max(maxValue, twoStepsPositiveIntensity);
     maxValue = max(maxValue, twoStepsNegativeIntensity);
     maxValue = max(maxValue, threeStepsPositiveIntensity);
     
     gl_FragColor = max(maxValue, threeStepsNegativeIntensity);
 }
);

// Radius 4
NSString *const kGPUImageRGBDilationRadiusFourFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepPositiveTextureCoordinate;
 varying vec2 oneStepNegativeTextureCoordinate;
 varying vec2 twoStepsPositiveTextureCoordinate;
 varying vec2 twoStepsNegativeTextureCoordinate;
 varying vec2 threeStepsPositiveTextureCoordinate;
 varying vec2 threeStepsNegativeTextureCoordinate;
 varying vec2 fourStepsPositiveTextureCoordinate;
 varying vec2 fourStepsNegativeTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     lowp vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
     lowp vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
     lowp vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
     lowp vec4 twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate);
     lowp vec4 twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate);
     lowp vec4 threeStepsPositiveIntensity = texture2D(inputImageTexture, threeStepsPositiveTextureCoordinate);
     lowp vec4 threeStepsNegativeIntensity = texture2D(inputImageTexture, threeStepsNegativeTextureCoordinate);
     lowp vec4 fourStepsPositiveIntensity = texture2D(inputImageTexture, fourStepsPositiveTextureCoordinate);
     lowp vec4 fourStepsNegativeIntensity = texture2D(inputImageTexture, fourStepsNegativeTextureCoordinate);
     
     lowp vec4 maxValue = max(centerIntensity, oneStepPositiveIntensity);
     maxValue = max(maxValue, oneStepNegativeIntensity);
     maxValue = max(maxValue, twoStepsPositiveIntensity);
     maxValue = max(maxValue, twoStepsNegativeIntensity);
     maxValue = max(maxValue, threeStepsPositiveIntensity);
     maxValue = max(maxValue, threeStepsNegativeIntensity);
     maxValue = max(maxValue, fourStepsPositiveIntensity);
     
     gl_FragColor = max(maxValue, fourStepsNegativeIntensity);
 }
);


@implementation GPUImageRGBDilationFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithRadius:(NSUInteger)dilationRadius;
{    
    NSString *fragmentShaderForThisRadius = nil;
    NSString *vertexShaderForThisRadius = nil;
    
    switch (dilationRadius)
    {
        case 0:
        case 1:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusOneVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageRGBDilationRadiusOneFragmentShaderString;
        }; break;
        case 2:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusTwoVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageRGBDilationRadiusTwoFragmentShaderString;
        }; break;
        case 3:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusThreeVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageRGBDilationRadiusThreeFragmentShaderString;
        }; break;
        case 4:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusFourVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageRGBDilationRadiusFourFragmentShaderString;
        }; break;
        default:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusFourVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageRGBDilationRadiusFourFragmentShaderString;
        }; break;
    }
    
    if (!(self = [super initWithFirstStageVertexShaderFromString:vertexShaderForThisRadius firstStageFragmentShaderFromString:fragmentShaderForThisRadius secondStageVertexShaderFromString:vertexShaderForThisRadius secondStageFragmentShaderFromString:fragmentShaderForThisRadius]))
    {
        return nil;
    }
    
    return self;
}

- (id)init;
{
    if (!(self = [self initWithRadius:1]))
    {
        return nil;
    }
    
    return self;
}

@end

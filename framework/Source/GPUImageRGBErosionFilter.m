#import "GPUImageRGBErosionFilter.h"
#import "GPUImageDilationFilter.h"

// Radius 1
NSString *const kGPUImageRGBErosionRadiusOneFragmentShaderString = SHADER_STRING
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
     
     lowp vec4 minValue = min(centerIntensity, oneStepPositiveIntensity);
     
     gl_FragColor = min(minValue, oneStepNegativeIntensity);
 }
);

// Radius 2
NSString *const kGPUImageRGBErosionRadiusTwoFragmentShaderString = SHADER_STRING
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
     
     lowp vec4 minValue = min(centerIntensity, oneStepPositiveIntensity);
     minValue = min(minValue, oneStepNegativeIntensity);
     minValue = min(minValue, twoStepsPositiveIntensity);
     
     gl_FragColor = min(minValue, twoStepsNegativeIntensity);
 }
 );

// Radius 3
NSString *const kGPUImageRGBErosionRadiusThreeFragmentShaderString = SHADER_STRING
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
     
     lowp vec4 minValue = min(centerIntensity, oneStepPositiveIntensity);
     minValue = min(minValue, oneStepNegativeIntensity);
     minValue = min(minValue, twoStepsPositiveIntensity);
     minValue = min(minValue, twoStepsNegativeIntensity);
     minValue = min(minValue, threeStepsPositiveIntensity);
     
     gl_FragColor = min(minValue, threeStepsNegativeIntensity);
 }
 );

// Radius 4
NSString *const kGPUImageRGBErosionRadiusFourFragmentShaderString = SHADER_STRING
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
     
     lowp vec4 minValue = min(centerIntensity, oneStepPositiveIntensity);
     minValue = min(minValue, oneStepNegativeIntensity);
     minValue = min(minValue, twoStepsPositiveIntensity);
     minValue = min(minValue, twoStepsNegativeIntensity);
     minValue = min(minValue, threeStepsPositiveIntensity);
     minValue = min(minValue, threeStepsNegativeIntensity);
     minValue = min(minValue, fourStepsPositiveIntensity);
     
     gl_FragColor = min(minValue, fourStepsNegativeIntensity);
 }
);

@implementation GPUImageRGBErosionFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithRadius:(NSUInteger)erosionRadius;
{    
    NSString *fragmentShaderForThisRadius = nil;
    NSString *vertexShaderForThisRadius = nil;
    
    switch (erosionRadius)
    {
        case 0:
        case 1:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusOneVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageRGBErosionRadiusOneFragmentShaderString;
        }; break;
        case 2:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusTwoVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageRGBErosionRadiusTwoFragmentShaderString;
        }; break;
        case 3:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusThreeVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageRGBErosionRadiusThreeFragmentShaderString;
        }; break;
        case 4:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusFourVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageRGBErosionRadiusFourFragmentShaderString;
        }; break;
        default:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusFourVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageRGBErosionRadiusFourFragmentShaderString;
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

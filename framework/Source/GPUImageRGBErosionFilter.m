#import "GPUImageRGBErosionFilter.h"
#import "GPUImageDilationFilter.h"

// Radius 1
NSString *const kGPUImageRGBErosionRadiusOneFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepPositiveTextureCoordinate;
 varying vec2 oneStepNegativeTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
     vec3 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate).rgb;
     vec3 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate).rgb;
     
     lowp vec3 minValue = min(centerIntensity.rgb, oneStepPositiveIntensity);
     minValue = min(minValue, oneStepNegativeIntensity);
     
     gl_FragColor = vec4(minValue, centerIntensity.a);
 }
);

// Radius 2
NSString *const kGPUImageRGBErosionRadiusTwoFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepPositiveTextureCoordinate;
 varying vec2 oneStepNegativeTextureCoordinate;
 varying vec2 twoStepsPositiveTextureCoordinate;
 varying vec2 twoStepsNegativeTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
     vec3 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate).rgb;
     vec3 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate).rgb;
     vec3 twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate).rgb;
     vec3 twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate).rgb;
     
     vec3 minValue = min(centerIntensity.rgb, oneStepPositiveIntensity);
     minValue = min(minValue, oneStepNegativeIntensity);
     minValue = min(minValue, twoStepsPositiveIntensity);
     minValue = min(minValue, twoStepsNegativeIntensity);
     
     gl_FragColor = vec4(minValue, centerIntensity.a);
 }
 );

// Radius 3
NSString *const kGPUImageRGBErosionRadiusThreeFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
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
     vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
     vec3 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate).rgb;
     vec3 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate).rgb;
     vec3 twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate).rgb;
     vec3 twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate).rgb;
     vec3 threeStepsPositiveIntensity = texture2D(inputImageTexture, threeStepsPositiveTextureCoordinate).rgb;
     vec3 threeStepsNegativeIntensity = texture2D(inputImageTexture, threeStepsNegativeTextureCoordinate).rgb;
     
     vec3 minValue = min(centerIntensity.rgb, oneStepPositiveIntensity);
     minValue = min(minValue, oneStepNegativeIntensity);
     minValue = min(minValue, twoStepsPositiveIntensity);
     minValue = min(minValue, twoStepsNegativeIntensity);
     minValue = min(minValue, threeStepsPositiveIntensity);
     minValue = min(minValue, threeStepsNegativeIntensity);
     
     gl_FragColor = vec4(minValue, centerIntensity.a);
 }
 );

// Radius 4
NSString *const kGPUImageRGBErosionRadiusFourFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
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
     vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
     vec3 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate).rgb;
     vec3 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate).rgb;
     vec3 twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate).rgb;
     vec3 twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate).rgb;
     vec3 threeStepsPositiveIntensity = texture2D(inputImageTexture, threeStepsPositiveTextureCoordinate).rgb;
     vec3 threeStepsNegativeIntensity = texture2D(inputImageTexture, threeStepsNegativeTextureCoordinate).rgb;
     vec3 fourStepsPositiveIntensity = texture2D(inputImageTexture, fourStepsPositiveTextureCoordinate).rgb;
     vec3 fourStepsNegativeIntensity = texture2D(inputImageTexture, fourStepsNegativeTextureCoordinate).rgb;
     
     vec3 minValue = min(centerIntensity.rgb, oneStepPositiveIntensity);
     minValue = min(minValue, oneStepNegativeIntensity);
     minValue = min(minValue, twoStepsPositiveIntensity);
     minValue = min(minValue, twoStepsNegativeIntensity);
     minValue = min(minValue, threeStepsPositiveIntensity);
     minValue = min(minValue, threeStepsNegativeIntensity);
     minValue = min(minValue, fourStepsPositiveIntensity);
     minValue = min(minValue, fourStepsNegativeIntensity);
     
     gl_FragColor = vec4(minValue, 1.0);
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

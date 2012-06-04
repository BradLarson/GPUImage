#import "GPUImageRGBDilationFilter.h"
#import "GPUImageDilationFilter.h"

// Radius 1
NSString *const kGPUImageRGBDilationRadiusOneFragmentShaderString = SHADER_STRING
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
     
     lowp vec3 maxValue = max(centerIntensity.rgb, oneStepPositiveIntensity);
     maxValue = max(maxValue, oneStepNegativeIntensity);
     
     gl_FragColor = vec4(maxValue, centerIntensity.a);
 }
);

// Radius 2
NSString *const kGPUImageRGBDilationRadiusTwoFragmentShaderString = SHADER_STRING
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
     
     vec3 maxValue = max(centerIntensity.rgb, oneStepPositiveIntensity);
     maxValue = max(maxValue, oneStepNegativeIntensity);
     maxValue = max(maxValue, twoStepsPositiveIntensity);
     maxValue = max(maxValue, twoStepsNegativeIntensity);
     
     gl_FragColor = vec4(maxValue, centerIntensity.a);
 }
);

// Radius 3
NSString *const kGPUImageRGBDilationRadiusThreeFragmentShaderString = SHADER_STRING
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
     
     vec3 maxValue = max(centerIntensity.rgb, oneStepPositiveIntensity);
     maxValue = max(maxValue, oneStepNegativeIntensity);
     maxValue = max(maxValue, twoStepsPositiveIntensity);
     maxValue = max(maxValue, twoStepsNegativeIntensity);
     maxValue = max(maxValue, threeStepsPositiveIntensity);
     maxValue = max(maxValue, threeStepsNegativeIntensity);
     
     gl_FragColor = vec4(maxValue, centerIntensity.a);
 }
);

// Radius 4
NSString *const kGPUImageRGBDilationRadiusFourFragmentShaderString = SHADER_STRING
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
     
     vec3 maxValue = max(centerIntensity.rgb, oneStepPositiveIntensity);
     maxValue = max(maxValue, oneStepNegativeIntensity);
     maxValue = max(maxValue, twoStepsPositiveIntensity);
     maxValue = max(maxValue, twoStepsNegativeIntensity);
     maxValue = max(maxValue, threeStepsPositiveIntensity);
     maxValue = max(maxValue, threeStepsNegativeIntensity);
     maxValue = max(maxValue, fourStepsPositiveIntensity);
     maxValue = max(maxValue, fourStepsNegativeIntensity);
     
     gl_FragColor = vec4(maxValue, 1.0);
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

#import "GPUImageDilationFilter.h"

@implementation GPUImageDilationFilter

// Radius: 1
NSString *const kGPUImageDilationRadiusOneVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 uniform float texelWidthOffset; 
 uniform float texelHeightOffset; 
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepPositiveTextureCoordinate;
 varying vec2 oneStepNegativeTextureCoordinate;
 
 void main()
 {
     gl_Position = position;
     
     vec2 offset = vec2(texelWidthOffset, texelHeightOffset);
     
     centerTextureCoordinate = inputTextureCoordinate;
     oneStepNegativeTextureCoordinate = inputTextureCoordinate - offset;
     oneStepPositiveTextureCoordinate = inputTextureCoordinate + offset;
 }
);

NSString *const kGPUImageDilationRadiusOneFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepPositiveTextureCoordinate;
 varying vec2 oneStepNegativeTextureCoordinate;
  
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     float centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate).r;
     float oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate).r;
     float oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate).r;
          
     lowp float maxValue = max(centerIntensity, oneStepPositiveIntensity);
     maxValue = max(maxValue, oneStepNegativeIntensity);

     gl_FragColor = vec4(vec3(maxValue), 1.0);
 }
);

// Radius: 2
NSString *const kGPUImageDilationRadiusTwoVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 uniform float texelWidthOffset; 
 uniform float texelHeightOffset; 
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepPositiveTextureCoordinate;
 varying vec2 oneStepNegativeTextureCoordinate;
 varying vec2 twoStepsPositiveTextureCoordinate;
 varying vec2 twoStepsNegativeTextureCoordinate;
 
 void main()
 {
     gl_Position = position;
     
     vec2 offset = vec2(texelWidthOffset, texelHeightOffset);
     
     centerTextureCoordinate = inputTextureCoordinate;
     oneStepNegativeTextureCoordinate = inputTextureCoordinate - offset;
     oneStepPositiveTextureCoordinate = inputTextureCoordinate + offset;
     twoStepsNegativeTextureCoordinate = inputTextureCoordinate - (offset * 2.0);
     twoStepsPositiveTextureCoordinate = inputTextureCoordinate + (offset * 2.0);
 }
);

NSString *const kGPUImageDilationRadiusTwoFragmentShaderString = SHADER_STRING
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
     float centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate).r;
     float oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate).r;
     float oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate).r;
     float twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate).r;
     float twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate).r;
     
     lowp float maxValue = max(centerIntensity, oneStepPositiveIntensity);
     maxValue = max(maxValue, oneStepNegativeIntensity);
     maxValue = max(maxValue, twoStepsPositiveIntensity);
     maxValue = max(maxValue, twoStepsNegativeIntensity);
     
     gl_FragColor = vec4(vec3(maxValue), 1.0);
 }
);

// Radius: 3
NSString *const kGPUImageDilationRadiusThreeVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 uniform float texelWidthOffset; 
 uniform float texelHeightOffset; 
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepPositiveTextureCoordinate;
 varying vec2 oneStepNegativeTextureCoordinate;
 varying vec2 twoStepsPositiveTextureCoordinate;
 varying vec2 twoStepsNegativeTextureCoordinate;
 varying vec2 threeStepsPositiveTextureCoordinate;
 varying vec2 threeStepsNegativeTextureCoordinate;
 
 void main()
 {
     gl_Position = position;
     
     vec2 offset = vec2(texelWidthOffset, texelHeightOffset);
     
     centerTextureCoordinate = inputTextureCoordinate;
     oneStepNegativeTextureCoordinate = inputTextureCoordinate - offset;
     oneStepPositiveTextureCoordinate = inputTextureCoordinate + offset;
     twoStepsNegativeTextureCoordinate = inputTextureCoordinate - (offset * 2.0);
     twoStepsPositiveTextureCoordinate = inputTextureCoordinate + (offset * 2.0);
     threeStepsNegativeTextureCoordinate = inputTextureCoordinate - (offset * 3.0);
     threeStepsPositiveTextureCoordinate = inputTextureCoordinate + (offset * 3.0);
 }
);

NSString *const kGPUImageDilationRadiusThreeFragmentShaderString = SHADER_STRING
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
     float centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate).r;
     float oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate).r;
     float oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate).r;
     float twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate).r;
     float twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate).r;
     float threeStepsPositiveIntensity = texture2D(inputImageTexture, threeStepsPositiveTextureCoordinate).r;
     float threeStepsNegativeIntensity = texture2D(inputImageTexture, threeStepsNegativeTextureCoordinate).r;
     
     lowp float maxValue = max(centerIntensity, oneStepPositiveIntensity);
     maxValue = max(maxValue, oneStepNegativeIntensity);
     maxValue = max(maxValue, twoStepsPositiveIntensity);
     maxValue = max(maxValue, twoStepsNegativeIntensity);
     maxValue = max(maxValue, threeStepsPositiveIntensity);
     maxValue = max(maxValue, threeStepsNegativeIntensity);
     
     gl_FragColor = vec4(vec3(maxValue), 1.0);
 }
);

// Radius: 4
NSString *const kGPUImageDilationRadiusFourVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 uniform float texelWidthOffset; 
 uniform float texelHeightOffset; 
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepPositiveTextureCoordinate;
 varying vec2 oneStepNegativeTextureCoordinate;
 varying vec2 twoStepsPositiveTextureCoordinate;
 varying vec2 twoStepsNegativeTextureCoordinate;
 varying vec2 threeStepsPositiveTextureCoordinate;
 varying vec2 threeStepsNegativeTextureCoordinate;
 varying vec2 fourStepsPositiveTextureCoordinate;
 varying vec2 fourStepsNegativeTextureCoordinate;
 
 void main()
 {
     gl_Position = position;
     
     vec2 offset = vec2(texelWidthOffset, texelHeightOffset);
     
     centerTextureCoordinate = inputTextureCoordinate;
     oneStepNegativeTextureCoordinate = inputTextureCoordinate - offset;
     oneStepPositiveTextureCoordinate = inputTextureCoordinate + offset;
     twoStepsNegativeTextureCoordinate = inputTextureCoordinate - (offset * 2.0);
     twoStepsPositiveTextureCoordinate = inputTextureCoordinate + (offset * 2.0);
     threeStepsNegativeTextureCoordinate = inputTextureCoordinate - (offset * 3.0);
     threeStepsPositiveTextureCoordinate = inputTextureCoordinate + (offset * 3.0);
     fourStepsNegativeTextureCoordinate = inputTextureCoordinate - (offset * 4.0);
     fourStepsPositiveTextureCoordinate = inputTextureCoordinate + (offset * 4.0);
 }
);

NSString *const kGPUImageDilationRadiusFourFragmentShaderString = SHADER_STRING
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
     float centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate).r;
     float oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate).r;
     float oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate).r;
     float twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate).r;
     float twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate).r;
     float threeStepsPositiveIntensity = texture2D(inputImageTexture, threeStepsPositiveTextureCoordinate).r;
     float threeStepsNegativeIntensity = texture2D(inputImageTexture, threeStepsNegativeTextureCoordinate).r;
     float fourStepsPositiveIntensity = texture2D(inputImageTexture, fourStepsPositiveTextureCoordinate).r;
     float fourStepsNegativeIntensity = texture2D(inputImageTexture, fourStepsNegativeTextureCoordinate).r;
     
     lowp float maxValue = max(centerIntensity, oneStepPositiveIntensity);
     maxValue = max(maxValue, oneStepNegativeIntensity);
     maxValue = max(maxValue, twoStepsPositiveIntensity);
     maxValue = max(maxValue, twoStepsNegativeIntensity);
     maxValue = max(maxValue, threeStepsPositiveIntensity);
     maxValue = max(maxValue, threeStepsNegativeIntensity);
     maxValue = max(maxValue, fourStepsPositiveIntensity);
     maxValue = max(maxValue, fourStepsNegativeIntensity);
     
     gl_FragColor = vec4(vec3(maxValue), 1.0);
 }
);

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
            fragmentShaderForThisRadius = kGPUImageDilationRadiusOneFragmentShaderString;
        }; break;
        case 2:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusTwoVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageDilationRadiusTwoFragmentShaderString;
        }; break;
        case 3:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusThreeVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageDilationRadiusThreeFragmentShaderString;
        }; break;
        case 4:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusFourVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageDilationRadiusFourFragmentShaderString;
        }; break;
        default:
        {
            vertexShaderForThisRadius = kGPUImageDilationRadiusFourVertexShaderString;
            fragmentShaderForThisRadius = kGPUImageDilationRadiusFourFragmentShaderString;
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

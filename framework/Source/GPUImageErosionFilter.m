#import "GPUImageErosionFilter.h"

@implementation GPUImageErosionFilter

// Radius: 1
NSString *const kGPUImageErosionRadiusOneVertexShaderString = SHADER_STRING
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

NSString *const kGPUImageErosionRadiusOneFragmentShaderString = SHADER_STRING
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
     
     lowp float minValue = min(centerIntensity, oneStepPositiveIntensity);
     minValue = min(minValue, oneStepNegativeIntensity);
     
     gl_FragColor = vec4(vec3(minValue), 1.0);
 }
 );

// Radius: 2
NSString *const kGPUImageErosionRadiusTwoVertexShaderString = SHADER_STRING
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

NSString *const kGPUImageErosionRadiusTwoFragmentShaderString = SHADER_STRING
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
     
     lowp float minValue = min(centerIntensity, oneStepPositiveIntensity);
     minValue = min(minValue, oneStepNegativeIntensity);
     minValue = min(minValue, twoStepsPositiveIntensity);
     minValue = min(minValue, twoStepsNegativeIntensity);
     
     gl_FragColor = vec4(vec3(minValue), 1.0);
 }
 );

// Radius: 3
NSString *const kGPUImageErosionRadiusThreeVertexShaderString = SHADER_STRING
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

NSString *const kGPUImageErosionRadiusThreeFragmentShaderString = SHADER_STRING
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
     
     lowp float minValue = min(centerIntensity, oneStepPositiveIntensity);
     minValue = min(minValue, oneStepNegativeIntensity);
     minValue = min(minValue, twoStepsPositiveIntensity);
     minValue = min(minValue, twoStepsNegativeIntensity);
     minValue = min(minValue, threeStepsPositiveIntensity);
     minValue = min(minValue, threeStepsNegativeIntensity);
     
     gl_FragColor = vec4(vec3(minValue), 1.0);
 }
 );

// Radius: 4
NSString *const kGPUImageErosionRadiusFourVertexShaderString = SHADER_STRING
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

NSString *const kGPUImageErosionRadiusFourFragmentShaderString = SHADER_STRING
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
     
     lowp float minValue = min(centerIntensity, oneStepPositiveIntensity);
     minValue = min(minValue, oneStepNegativeIntensity);
     minValue = min(minValue, twoStepsPositiveIntensity);
     minValue = min(minValue, twoStepsNegativeIntensity);
     minValue = min(minValue, threeStepsPositiveIntensity);
     minValue = min(minValue, threeStepsNegativeIntensity);
     minValue = min(minValue, fourStepsPositiveIntensity);
     minValue = min(minValue, fourStepsNegativeIntensity);
     
     gl_FragColor = vec4(vec3(minValue), 1.0);
 }
 );

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithRadius:(NSUInteger)erosionRadius;
{    
    switch (erosionRadius)
    {
        case 0:
        case 1:
        {
            if (!(self = [super initWithFirstStageVertexShaderFromString:kGPUImageErosionRadiusOneVertexShaderString firstStageFragmentShaderFromString:kGPUImageErosionRadiusOneFragmentShaderString secondStageVertexShaderFromString:kGPUImageErosionRadiusOneVertexShaderString secondStageFragmentShaderFromString:kGPUImageErosionRadiusOneFragmentShaderString]))
            {
                return nil;
            }
        }; break;
        case 2:
        {
            if (!(self = [super initWithFirstStageVertexShaderFromString:kGPUImageErosionRadiusTwoVertexShaderString firstStageFragmentShaderFromString:kGPUImageErosionRadiusTwoFragmentShaderString secondStageVertexShaderFromString:kGPUImageErosionRadiusTwoVertexShaderString secondStageFragmentShaderFromString:kGPUImageErosionRadiusTwoFragmentShaderString]))
            {
                return nil;
            }
        }; break;
        case 3:
        {
            if (!(self = [super initWithFirstStageVertexShaderFromString:kGPUImageErosionRadiusThreeVertexShaderString firstStageFragmentShaderFromString:kGPUImageErosionRadiusThreeFragmentShaderString secondStageVertexShaderFromString:kGPUImageErosionRadiusThreeVertexShaderString secondStageFragmentShaderFromString:kGPUImageErosionRadiusThreeFragmentShaderString]))
            {
                return nil;
            }
        }; break;
        case 4:
        {
            if (!(self = [super initWithFirstStageVertexShaderFromString:kGPUImageErosionRadiusFourVertexShaderString firstStageFragmentShaderFromString:kGPUImageErosionRadiusFourFragmentShaderString secondStageVertexShaderFromString:kGPUImageErosionRadiusFourVertexShaderString secondStageFragmentShaderFromString:kGPUImageErosionRadiusFourFragmentShaderString]))
            {
                return nil;
            }
        }; break;
        default:
        {
            if (!(self = [super initWithFirstStageVertexShaderFromString:kGPUImageErosionRadiusFourVertexShaderString firstStageFragmentShaderFromString:kGPUImageErosionRadiusFourFragmentShaderString secondStageVertexShaderFromString:kGPUImageErosionRadiusFourVertexShaderString secondStageFragmentShaderFromString:kGPUImageErosionRadiusFourFragmentShaderString]))
            {
                return nil;
            }
        }; break;
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

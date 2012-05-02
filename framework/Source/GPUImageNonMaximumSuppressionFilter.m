#import "GPUImageNonMaximumSuppressionFilter.h"

NSString *const kGPUImageNonMaximumSuppressionVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 uniform highp float texelWidthOffset; 
 uniform highp float texelHeightOffset; 
 uniform highp float blurSize;
 
 varying highp vec2 centerTextureCoordinate;
 varying highp vec2 oneStepNegativeTextureCoordinate;
 varying highp vec2 twoStepsNegativeTextureCoordinate;
 varying highp vec2 oneStepPositiveTextureCoordinate;
 varying highp vec2 twoStepsPositiveTextureCoordinate;
 
 void main()
 {
     gl_Position = position;
     
     vec2 firstOffset = vec2(texelWidthOffset, texelHeightOffset) * 1.0;
     vec2 secondOffset = vec2(texelWidthOffset, texelHeightOffset) * 2.0;
     
     centerTextureCoordinate = inputTextureCoordinate;
     oneStepNegativeTextureCoordinate = inputTextureCoordinate - firstOffset;
     twoStepsNegativeTextureCoordinate = inputTextureCoordinate - secondOffset;
     oneStepPositiveTextureCoordinate = inputTextureCoordinate + firstOffset;
     twoStepsPositiveTextureCoordinate = inputTextureCoordinate + secondOffset;
 }
);


NSString *const kGPUImageNonMaximumSuppressionFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 varying highp vec2 centerTextureCoordinate;
 varying highp vec2 oneStepNegativeTextureCoordinate;
 varying highp vec2 twoStepsNegativeTextureCoordinate;
 varying highp vec2 oneStepPositiveTextureCoordinate;
 varying highp vec2 twoStepsPositiveTextureCoordinate;
 
 void main()
 {
     lowp float fragmentColor = texture2D(inputImageTexture, centerTextureCoordinate).r;
     lowp float oneStepNegativeFragmentColor = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate).r;
     lowp float twoStepsNegativeFragmentColor = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate).r;
     lowp float oneStepPositiveFragmentColor = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate).r;
     lowp float twoStepsPositiveFragmentColor = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate).r;
     
     lowp float maxValue = max(fragmentColor, oneStepNegativeFragmentColor);
     maxValue = max(maxValue, twoStepsNegativeFragmentColor);
     maxValue = max(maxValue, oneStepPositiveFragmentColor);
     maxValue = max(maxValue, twoStepsPositiveFragmentColor);
     
     gl_FragColor = vec4(fragmentColor * step(maxValue, fragmentColor));
 }
);

@implementation GPUImageNonMaximumSuppressionFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFirstStageVertexShaderFromString:kGPUImageNonMaximumSuppressionVertexShaderString firstStageFragmentShaderFromString:kGPUImageNonMaximumSuppressionFragmentShaderString secondStageVertexShaderFromString:kGPUImageNonMaximumSuppressionVertexShaderString secondStageFragmentShaderFromString:kGPUImageNonMaximumSuppressionFragmentShaderString]))
    {
		return nil;
    }
    
    verticalPassTexelWidthOffsetUniform = [filterProgram uniformIndex:@"texelWidthOffset"];
    verticalPassTexelHeightOffsetUniform = [filterProgram uniformIndex:@"texelHeightOffset"];
    
    horizontalPassTexelWidthOffsetUniform = [secondFilterProgram uniformIndex:@"texelWidthOffset"];
    horizontalPassTexelHeightOffsetUniform = [secondFilterProgram uniformIndex:@"texelHeightOffset"];
    
    return self;
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(verticalPassTexelWidthOffsetUniform, 0.0);
    glUniform1f(verticalPassTexelHeightOffsetUniform, 1.0 / filterFrameSize.height);
    
    [secondFilterProgram use];
    glUniform1f(horizontalPassTexelWidthOffsetUniform, 1.0 / filterFrameSize.width);
    glUniform1f(horizontalPassTexelHeightOffsetUniform, 0.0);
}

@end


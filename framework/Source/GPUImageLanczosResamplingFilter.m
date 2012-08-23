#import "GPUImageLanczosResamplingFilter.h"

NSString *const kGPUImageLanczosVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 uniform float texelWidthOffset;
 uniform float texelHeightOffset;
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepLeftTextureCoordinate;
 varying vec2 twoStepsLeftTextureCoordinate;
 varying vec2 threeStepsLeftTextureCoordinate;
 varying vec2 fourStepsLeftTextureCoordinate;
 varying vec2 oneStepRightTextureCoordinate;
 varying vec2 twoStepsRightTextureCoordinate;
 varying vec2 threeStepsRightTextureCoordinate;
 varying vec2 fourStepsRightTextureCoordinate;

 void main()
 {
     gl_Position = position;
     
     vec2 firstOffset = vec2(texelWidthOffset, texelHeightOffset);
     vec2 secondOffset = vec2(2.0 * texelWidthOffset, 2.0 * texelHeightOffset);
     vec2 thirdOffset = vec2(3.0 * texelWidthOffset, 3.0 * texelHeightOffset);
     vec2 fourthOffset = vec2(4.0 * texelWidthOffset, 4.0 * texelHeightOffset);
     
     centerTextureCoordinate = inputTextureCoordinate;
     oneStepLeftTextureCoordinate = inputTextureCoordinate - firstOffset;
     twoStepsLeftTextureCoordinate = inputTextureCoordinate - secondOffset;
     threeStepsLeftTextureCoordinate = inputTextureCoordinate - thirdOffset;
     fourStepsLeftTextureCoordinate = inputTextureCoordinate - fourthOffset;
     oneStepRightTextureCoordinate = inputTextureCoordinate + firstOffset;
     twoStepsRightTextureCoordinate = inputTextureCoordinate + secondOffset;
     threeStepsRightTextureCoordinate = inputTextureCoordinate + thirdOffset;
     fourStepsRightTextureCoordinate = inputTextureCoordinate + fourthOffset;
 }
);


NSString *const kGPUImageLanczosFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 uniform sampler2D inputImageTexture;
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepLeftTextureCoordinate;
 varying vec2 twoStepsLeftTextureCoordinate;
 varying vec2 threeStepsLeftTextureCoordinate;
 varying vec2 fourStepsLeftTextureCoordinate;
 varying vec2 oneStepRightTextureCoordinate;
 varying vec2 twoStepsRightTextureCoordinate;
 varying vec2 threeStepsRightTextureCoordinate;
 varying vec2 fourStepsRightTextureCoordinate;

 // sinc(x) * sinc(x/a) = (a * sin(pi * x) * sin(pi * x / a)) / (pi^2 * x^2)
 // Assuming a Lanczos constant of 2.0, and scaling values to max out at x = +/- 1.5
 
 void main()
 {
     lowp vec4 fragmentColor = texture2D(inputImageTexture, centerTextureCoordinate) * 0.38026;
     
     fragmentColor += texture2D(inputImageTexture, oneStepLeftTextureCoordinate) * 0.27667;
     fragmentColor += texture2D(inputImageTexture, oneStepRightTextureCoordinate) * 0.27667;
     
     fragmentColor += texture2D(inputImageTexture, twoStepsLeftTextureCoordinate) * 0.08074;
     fragmentColor += texture2D(inputImageTexture, twoStepsRightTextureCoordinate) * 0.08074;

     fragmentColor += texture2D(inputImageTexture, threeStepsLeftTextureCoordinate) * -0.02612;
     fragmentColor += texture2D(inputImageTexture, threeStepsRightTextureCoordinate) * -0.02612;

     fragmentColor += texture2D(inputImageTexture, fourStepsLeftTextureCoordinate) * -0.02143;
     fragmentColor += texture2D(inputImageTexture, fourStepsRightTextureCoordinate) * -0.02143;

     gl_FragColor = fragmentColor;
 }
 );

@implementation GPUImageLanczosResamplingFilter

@synthesize originalImageSize = _originalImageSize;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFirstStageVertexShaderFromString:kGPUImageLanczosVertexShaderString firstStageFragmentShaderFromString:kGPUImageLanczosFragmentShaderString secondStageVertexShaderFromString:kGPUImageLanczosVertexShaderString secondStageFragmentShaderFromString:kGPUImageLanczosFragmentShaderString]))
    {
		return nil;
    }
        
    return self;
}

// Base texture sampling offset on the input image, not the final size
- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    self.originalImageSize = newSize;
    [super setInputSize:newSize atIndex:textureIndex];
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
        
        // The first pass through the framebuffer may rotate the inbound image, so need to account for that by changing up the kernel ordering for that pass
        if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
        {
            glUniform1f(verticalPassTexelWidthOffsetUniform, 1.0 / _originalImageSize.height);
            glUniform1f(verticalPassTexelHeightOffsetUniform, 0.0);
        }
        else
        {
            glUniform1f(verticalPassTexelWidthOffsetUniform, 0.0);
            glUniform1f(verticalPassTexelHeightOffsetUniform, 1.0 / _originalImageSize.height);
        }
        
        [GPUImageOpenGLESContext setActiveShaderProgram:secondFilterProgram];
        glUniform1f(horizontalPassTexelWidthOffsetUniform, 1.0 / _originalImageSize.width);
        glUniform1f(horizontalPassTexelHeightOffsetUniform, 0.0);
    });
}


@end

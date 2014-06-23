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

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
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
#else
NSString *const kGPUImageLanczosFragmentShaderString = SHADER_STRING
(
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
     vec4 fragmentColor = texture2D(inputImageTexture, centerTextureCoordinate) * 0.38026;
     
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
#endif

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
        // The first pass through the framebuffer may rotate the inbound image, so need to account for that by changing up the kernel ordering for that pass
        if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
        {
            verticalPassTexelWidthOffset = 1.0 / _originalImageSize.height;
            verticalPassTexelHeightOffset = 0.0;
        }
        else
        {
            verticalPassTexelWidthOffset = 0.0;
            verticalPassTexelHeightOffset = 1.0 / _originalImageSize.height;
        }
        
        horizontalPassTexelWidthOffset = 1.0 / _originalImageSize.width;
        horizontalPassTexelHeightOffset = 0.0;
    });
}


- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    [GPUImageContext setActiveShaderProgram:filterProgram];
    
    CGSize currentFBOSize = [self sizeOfFBO];
    if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
    {
        currentFBOSize.height = self.originalImageSize.height;
    }
    else
    {
        currentFBOSize.width = self.originalImageSize.width;
    }
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:currentFBOSize textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    
    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
	
	glUniform1i(filterInputTextureUniform, 2);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
	glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [firstInputFramebuffer unlock];
    
    // Run the second stage of the two-pass filter
    [GPUImageContext setActiveShaderProgram:secondFilterProgram];
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, 0);
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, 0);
    secondOutputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [secondOutputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [secondOutputFramebuffer lock];
    }

    [self setUniformsForProgramAtIndex:1];
    
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, [outputFramebuffer texture]);
    glVertexAttribPointer(secondFilterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [[self class] textureCoordinatesForRotation:kGPUImageNoRotation]);
    
	glUniform1i(secondFilterInputTextureUniform, 3);
    
    glVertexAttribPointer(secondFilterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [outputFramebuffer unlock];
    outputFramebuffer = nil;
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

@end

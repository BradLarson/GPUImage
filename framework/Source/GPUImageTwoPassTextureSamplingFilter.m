#import "GPUImageTwoPassTextureSamplingFilter.h"

@implementation GPUImageTwoPassTextureSamplingFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithFirstStageVertexShaderFromString:(NSString *)firstStageVertexShaderString firstStageFragmentShaderFromString:(NSString *)firstStageFragmentShaderString secondStageVertexShaderFromString:(NSString *)secondStageVertexShaderString secondStageFragmentShaderFromString:(NSString *)secondStageFragmentShaderString
{
    if (!(self = [super initWithFirstStageVertexShaderFromString:firstStageVertexShaderString firstStageFragmentShaderFromString:firstStageFragmentShaderString secondStageVertexShaderFromString:secondStageVertexShaderString secondStageFragmentShaderFromString:secondStageFragmentShaderString]))
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

    // The first pass through the framebuffer may rotate the inbound image, so need to account for that by changing up the kernel ordering for that pass
    if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
    {
        glUniform1f(verticalPassTexelWidthOffsetUniform, 1.0 / filterFrameSize.height);
        glUniform1f(verticalPassTexelHeightOffsetUniform, 0.0);
    }
    else
    {
        glUniform1f(verticalPassTexelWidthOffsetUniform, 0.0);
        glUniform1f(verticalPassTexelHeightOffsetUniform, 1.0 / filterFrameSize.height);
    }
    
    [secondFilterProgram use];
    glUniform1f(horizontalPassTexelWidthOffsetUniform, 1.0 / filterFrameSize.width);
    glUniform1f(horizontalPassTexelHeightOffsetUniform, 0.0);
}

@end

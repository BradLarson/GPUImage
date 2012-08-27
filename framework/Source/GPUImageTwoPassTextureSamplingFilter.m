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

- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;
{
    if (programIndex == 0)
    {
        glUniform1f(verticalPassTexelWidthOffsetUniform, verticalPassTexelWidthOffset);
        glUniform1f(verticalPassTexelHeightOffsetUniform, verticalPassTexelHeightOffset);
    }
    else
    {
        glUniform1f(horizontalPassTexelWidthOffsetUniform, horizontalPassTexelWidthOffset);
        glUniform1f(horizontalPassTexelHeightOffsetUniform, horizontalPassTexelHeightOffset);
    }
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        // The first pass through the framebuffer may rotate the inbound image, so need to account for that by changing up the kernel ordering for that pass
        if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
        {
            verticalPassTexelWidthOffset = 1.0 / filterFrameSize.height;
            verticalPassTexelHeightOffset = 0.0;
        }
        else
        {
            verticalPassTexelWidthOffset = 0.0;
            verticalPassTexelHeightOffset = 1.0 / filterFrameSize.height;
        }
        
        horizontalPassTexelWidthOffset = 1.0 / filterFrameSize.width;
        horizontalPassTexelHeightOffset = 0.0;
    });
}

@end

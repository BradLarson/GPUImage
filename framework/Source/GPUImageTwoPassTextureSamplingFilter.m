#import "GPUImageTwoPassTextureSamplingFilter.h"

@implementation GPUImageTwoPassTextureSamplingFilter

@synthesize verticalTexelSpacing = _verticalTexelSpacing;
@synthesize horizontalTexelSpacing = _horizontalTexelSpacing;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithFirstStageVertexShaderFromString:(NSString *)firstStageVertexShaderString firstStageFragmentShaderFromString:(NSString *)firstStageFragmentShaderString secondStageVertexShaderFromString:(NSString *)secondStageVertexShaderString secondStageFragmentShaderFromString:(NSString *)secondStageFragmentShaderString
{
    if (!(self = [super initWithFirstStageVertexShaderFromString:firstStageVertexShaderString firstStageFragmentShaderFromString:firstStageFragmentShaderString secondStageVertexShaderFromString:secondStageVertexShaderString secondStageFragmentShaderFromString:secondStageFragmentShaderString]))
    {
		return nil;
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];

        verticalPassTexelWidthOffsetUniform = [filterProgram uniformIndex:@"texelWidthOffset"];
        verticalPassTexelHeightOffsetUniform = [filterProgram uniformIndex:@"texelHeightOffset"];
        
        horizontalPassTexelWidthOffsetUniform = [secondFilterProgram uniformIndex:@"texelWidthOffset"];
        horizontalPassTexelHeightOffsetUniform = [secondFilterProgram uniformIndex:@"texelHeightOffset"];
    });
    
    self.verticalTexelSpacing = 1.0;
    self.horizontalTexelSpacing = 1.0;
    
    return self;
}

- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;
{
    [super setUniformsForProgramAtIndex:programIndex];
    
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
            verticalPassTexelWidthOffset = _verticalTexelSpacing / filterFrameSize.height;
            verticalPassTexelHeightOffset = 0.0;
        }
        else
        {
            verticalPassTexelWidthOffset = 0.0;
            verticalPassTexelHeightOffset = _verticalTexelSpacing / filterFrameSize.height;
        }
        
        horizontalPassTexelWidthOffset = _horizontalTexelSpacing / filterFrameSize.width;
        horizontalPassTexelHeightOffset = 0.0;
    });
}

#pragma mark -
#pragma mark Accessors

- (void)setVerticalTexelSpacing:(CGFloat)newValue;
{
    _verticalTexelSpacing = newValue;
    [self setupFilterForSize:[self sizeOfFBO]];
}

- (void)setHorizontalTexelSpacing:(CGFloat)newValue;
{
    _horizontalTexelSpacing = newValue;
    [self setupFilterForSize:[self sizeOfFBO]];
}

@end

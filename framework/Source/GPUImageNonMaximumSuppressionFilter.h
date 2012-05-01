#import "GPUImageTwoPassFilter.h"

@interface GPUImageNonMaximumSuppressionFilter : GPUImageTwoPassFilter
{
    GLint verticalPassTexelWidthOffsetUniform, verticalPassTexelHeightOffsetUniform, horizontalPassTexelWidthOffsetUniform, horizontalPassTexelHeightOffsetUniform;
}

@end

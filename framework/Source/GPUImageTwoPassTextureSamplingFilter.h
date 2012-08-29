#import "GPUImageTwoPassFilter.h"

@interface GPUImageTwoPassTextureSamplingFilter : GPUImageTwoPassFilter
{
    GLint verticalPassTexelWidthOffsetUniform, verticalPassTexelHeightOffsetUniform, horizontalPassTexelWidthOffsetUniform, horizontalPassTexelHeightOffsetUniform;
    GLfloat verticalPassTexelWidthOffset, verticalPassTexelHeightOffset, horizontalPassTexelWidthOffset, horizontalPassTexelHeightOffset;
}
@end

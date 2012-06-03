#import "GPUImageTwoPassFilter.h"

@interface GPUImageTwoPassTextureSamplingFilter : GPUImageTwoPassFilter
{
    GLint verticalPassTexelWidthOffsetUniform, verticalPassTexelHeightOffsetUniform, horizontalPassTexelWidthOffsetUniform, horizontalPassTexelHeightOffsetUniform;
}
@end

#import "GPUImageTwoPassFilter.h"

/** A hardware-accelerated 9-hit box blur of an image
 */
@interface GPUImageBoxBlurFilter : GPUImageTwoPassFilter
{
    GLint verticalPassTexelWidthOffsetUniform, verticalPassTexelHeightOffsetUniform, horizontalPassTexelWidthOffsetUniform, horizontalPassTexelHeightOffsetUniform, blurSizeUniform;
}

@end

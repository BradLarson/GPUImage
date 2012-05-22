#import "GPUImageTwoPassFilter.h"

/** A hardware-accelerated 9-hit box blur of an image
 */
@interface GPUImageBoxBlurFilter : GPUImageTwoPassFilter
{
    GLint verticalPassTexelWidthOffsetUniform, verticalPassTexelHeightOffsetUniform, horizontalPassTexelWidthOffsetUniform, horizontalPassTexelHeightOffsetUniform, firstBlurSizeUniform, secondBlurSizeUniform;
}

/// A scaling for the size of the applied blur, default of 1.0
@property(readwrite, nonatomic) CGFloat blurSize;

@end

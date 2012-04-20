#import "GPUImageTwoPassFilter.h"

@interface GPUImageFastBlurFilter : GPUImageTwoPassFilter
{
    GLint verticalPassTexelWidthOffsetUniform, verticalPassTexelHeightOffsetUniform, horizontalPassTexelWidthOffsetUniform, horizontalPassTexelHeightOffsetUniform, blurSizeUniform;
}

// The number of times to sequentially blur the incoming image. The more passes, the slower the filter.
@property(readwrite, nonatomic) NSUInteger blurPasses;

// A scaling for the size of the applied blur, default of 1.0
@property(readwrite, nonatomic) CGFloat blurSize;

@end

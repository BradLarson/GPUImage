#import "GPUImageTwoPassFilter.h"

@interface GPUImageGaussianBlurFilter : GPUImageTwoPassFilter 
{
    GLint horizontalGaussianArrayUniform, horizontalBlurSizeUniform, verticalGaussianArrayUniform, verticalBlurSizeUniform;
    GLint verticalPassTexelWidthOffsetUniform, verticalPassTexelHeightOffsetUniform, horizontalPassTexelWidthOffsetUniform, horizontalPassTexelHeightOffsetUniform, blurSizeUniform;
}

// A multiplier for the blur size, ranging from 0.0 on up, with a default of 1.0
@property (readwrite, nonatomic) CGFloat blurSize;

- (void)setGaussianValues;

@end

#import "GPUImageTwoPassTextureSamplingFilter.h"

/** A more generalized 9x9 Gaussian blur filter
 */
@interface GPUImageGaussianBlurFilter : GPUImageTwoPassTextureSamplingFilter 
{
    GLint horizontalBlurSizeUniform, verticalBlurSizeUniform;
}

/** A multiplier for the blur size, ranging from 0.0 on up, with a default of 1.0
 */
@property (readwrite, nonatomic) CGFloat blurSize;

@end

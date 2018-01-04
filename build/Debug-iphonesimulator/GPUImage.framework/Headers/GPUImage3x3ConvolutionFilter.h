#import "GPUImage3x3TextureSamplingFilter.h"

/** Runs a 3x3 convolution kernel against the image
 */
@interface GPUImage3x3ConvolutionFilter : GPUImage3x3TextureSamplingFilter
{
    GLint convolutionMatrixUniform;
}

/** Convolution kernel to run against the image
 
 The convolution kernel is a 3x3 matrix of values to apply to the pixel and its 8 surrounding pixels.
 The matrix is specified in row-major order, with the top left pixel being one.one and the bottom right three.three
 If the values in the matrix don't add up to 1.0, the image could be brightened or darkened.
 */
@property(readwrite, nonatomic) GPUMatrix3x3 convolutionKernel;

@end

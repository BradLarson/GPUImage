#import "GPUImageFilterGroup.h"

@class GPUImageGaussianBlurFilter;
@class GPUImageXYDerivativeFilter;
@class GPUImageGrayscaleFilter;
@class GPUImageFastBlurFilter;
@class GPUImageNonMaximumSuppressionFilter;

/** Harris corner detector
 
 First pass: reduce to luminance and take the derivative of the luminance texture (GPUImageXYDerivativeFilter)
 
 Second pass: blur the derivative (GPUImageFastBlurFilter)
 
 Third pass: apply the Harris corner detection calculation
 
 This is the Harris corner detector, as described in 
 C. Harris and M. Stephens. A Combined Corner and Edge Detector. Proc. Alvey Vision Conf., Univ. Manchester, pp. 147-151, 1988.
 */
@interface GPUImageHarrisCornerDetectionFilter : GPUImageFilterGroup
{
    GPUImageXYDerivativeFilter *derivativeFilter;
//    GPUImageGaussianBlurFilter *blurFilter;
    GPUImageFastBlurFilter *preblurFilter, *blurFilter;
    GPUImageFilter *harrisCornerDetectionFilter;
    GPUImageNonMaximumSuppressionFilter *nonMaximumSuppressionFilter;
    GPUImageFilter *simpleThresholdFilter;
}

/** A multiplier for the underlying blur size, ranging from 0.0 on up, with a default of 1.0
 */
@property (readwrite, nonatomic) CGFloat blurSize;

@end

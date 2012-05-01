#import "GPUImageFilterGroup.h"

@class GPUImageGaussianBlurFilter;
@class GPUImageXYDerivativeFilter;
@class GPUImageGrayscaleFilter;
@class GPUImageFastBlurFilter;
@class GPUImageNonMaximumSuppressionFilter;

@interface GPUImageHarrisCornerDetectionFilter : GPUImageFilterGroup
{
    GPUImageXYDerivativeFilter *derivativeFilter;
//    GPUImageGaussianBlurFilter *blurFilter;
    GPUImageFastBlurFilter *preblurFilter, *blurFilter;
    GPUImageFilter *harrisCornerDetectionFilter;
    GPUImageNonMaximumSuppressionFilter *nonMaximumSuppressionFilter;
    GPUImageFilter *simpleThresholdFilter;
}
// A multiplier for the underlying blur size, ranging from 0.0 on up, with a default of 1.0
@property (readwrite, nonatomic) CGFloat blurSize;

@end

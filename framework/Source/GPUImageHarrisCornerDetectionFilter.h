#import "GPUImageFilterGroup.h"

@class GPUImageGaussianBlurFilter;
@class GPUImageXYDerivativeFilter;
@class GPUImageGrayscaleFilter;
@class GPUImageFastBlurFilter;

@interface GPUImageHarrisCornerDetectionFilter : GPUImageFilterGroup
{
    GPUImageGrayscaleFilter *luminanceFilter;
    GPUImageXYDerivativeFilter *derivativeFilter;
//    GPUImageGaussianBlurFilter *blurFilter;
    GPUImageFastBlurFilter *blurFilter;
    GPUImageFilter *harrisCornerDetectionFilter;
    // Non maximum suppression filter
    GPUImageFilter *simpleThresholdFilter;
}
// A multiplier for the underlying blur size, ranging from 0.0 on up, with a default of 1.0
@property (readwrite, nonatomic) CGFloat blurSize;

@end

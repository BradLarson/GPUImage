#import "GPUImageFilter.h"

@interface GPUImageGaussianBlurFilter : GPUImageFilter {
    GPUImageFilter *horizontalBlur;
    GPUImageFilter *verticalBlur;
}

@property (readwrite, nonatomic) CGFloat blurSize;

- (void) setGaussianValues;

@end

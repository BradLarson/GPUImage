#import "GPUImageGaussianBlurFilter.h"

@interface GPUImageGaussianSelectiveBlurFilter : GPUImageGaussianBlurFilter {
}

@property (readwrite, nonatomic) CGFloat excludeCircleRadius;
@property (readwrite, nonatomic) CGPoint excludeCirclePoint;
@property (readwrite, nonatomic) CGFloat excludeBlurSize;

@end

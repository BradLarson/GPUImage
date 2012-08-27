#import "GPUImageFilterGroup.h"

@interface GPUImageAverageLuminanceThresholdFilter : GPUImageFilterGroup

// This is multiplied by the continually calculated average image luminosity to arrive at the final threshold. Default is 1.0.
@property(readwrite, nonatomic) CGFloat thresholdMultiplier;

@end

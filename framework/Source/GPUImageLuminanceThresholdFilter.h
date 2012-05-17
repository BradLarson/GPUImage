#import "GPUImageFilter.h"

@interface GPUImageLuminanceThresholdFilter : GPUImageFilter
{
    GLint thresholdUniform;
}

// Anything above this luminance will be white, and anything below black. Ranges from 0.0 to 1.0, with 0.5 as the default
@property(readwrite, nonatomic) CGFloat threshold; 

@end

#import "GPUImageFilter.h"

@interface GPUImageContrastFilter : GPUImageFilter
{
    GLint contrastUniform;
}

// Contrast ranges from 0.0 to 4.0 (max contrast), with 1.0 as the normal level
@property(readwrite, nonatomic) CGFloat contrast; 

@end

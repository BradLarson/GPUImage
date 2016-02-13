#import "GPUImageFilter.h"

@interface GPUImageColorInvertFilter : GPUImageFilter
{
    GLint invertUniform;
}

@property(readwrite, nonatomic) CGFloat invert;

@end

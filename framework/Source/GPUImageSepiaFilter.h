#import "GPUImageFilter.h"

@interface GPUImageSepiaFilter : GPUImageFilter
{
    GLint intensityUniform;
}

@property(readwrite, nonatomic) CGFloat intensity;

@end

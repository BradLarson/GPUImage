#import "GPUImageFilter.h"

@interface GPUImagePixellateFilter : GPUImageFilter
{
    GLint fractionalWidthOfAPixelUniform;
}

@property(readwrite, nonatomic) CGFloat fractionalWidthOfAPixel;

@end

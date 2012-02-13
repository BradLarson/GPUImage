#import "GPUImageFilter.h"

@interface GPUImagePixellateFilter : GPUImageFilter
{
    GLint fractionalWidthOfAPixelUniform;
    CGFloat fractionalWidthOfAPixel;
}

@property(readwrite, nonatomic) CGFloat fractionalWidthOfAPixel;

@end

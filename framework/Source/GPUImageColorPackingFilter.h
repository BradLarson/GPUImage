#import "GPUImageFilter.h"

@interface GPUImageColorPackingFilter : GPUImageFilter
{
    GLint texelWidthUniform, texelHeightUniform;
    
    CGFloat texelWidth, texelHeight;
}

@end

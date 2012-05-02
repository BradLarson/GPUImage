#import "GPUImageFilter.h"

@interface GPUImageColorMatrixFilter : GPUImageFilter
{
    GLint colorMatrixUniform;
    GLint intensityUniform;
}

@property(readwrite, nonatomic) GPUMatrix4x4 colorMatrix;
@property(readwrite, nonatomic) CGFloat intensity;

@end

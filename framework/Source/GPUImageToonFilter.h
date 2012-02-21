#import "GPUImageFilter.h"

@interface GPUImageToonFilter : GPUImageFilter
{
    GLint imageWidthFactorUniform, imageHeightFactorUniform;
}

// The image width and height factors tweak the appearance of the edges. Normally, they are close to the image size in pixels
@property(readwrite, nonatomic) CGFloat imageWidthFactor; 
@property(readwrite, nonatomic) CGFloat imageHeightFactor; 

@end

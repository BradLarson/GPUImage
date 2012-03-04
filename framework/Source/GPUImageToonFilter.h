#import "GPUImageFilter.h"

@interface GPUImageToonFilter : GPUImageFilter
{
    GLint imageWidthFactorUniform, imageHeightFactorUniform;
    BOOL hasOverriddenImageSizeFactor;
}

// The image width and height factors tweak the appearance of the edges. By default, they match the filter size in pixels
@property(readwrite, nonatomic) CGFloat imageWidthFactor; 
@property(readwrite, nonatomic) CGFloat imageHeightFactor; 

@end

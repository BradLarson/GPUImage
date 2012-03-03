#import "GPUImageFilter.h"

@interface GPUImageSobelEdgeDetectionFilter : GPUImageFilter
{
    GLint intensityUniform, imageWidthFactorUniform, imageHeightFactorUniform;
    BOOL hasOverriddenImageSizeFactor;
    CGFloat _imageWidthFactor;
    CGFloat _imageHeightFactor;
}

// The image width and height factors tweak the appearance of the edges. By default, they match the filter size in pixels
@property(readwrite, nonatomic) CGFloat imageWidthFactor; 
@property(readwrite, nonatomic) CGFloat imageHeightFactor; 

@end

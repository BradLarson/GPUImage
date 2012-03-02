#import "GPUImageFilter.h"

@interface GPUImageSobelEdgeDetectionFilter : GPUImageFilter
{
    GLint intensityUniform, imageWidthFactorUniform, imageHeightFactorUniform;
    BOOL hasOverriddenImageSizeFactor;
}

// Intensity is the degree to which the edges are overlaid on the image. 1.0 is the default, and is complete visibility for them
@property(readwrite, nonatomic) CGFloat intensity; 
// The image width and height factors tweak the appearance of the edges. By default, they match the filter size in pixels
@property(readwrite, nonatomic) CGFloat imageWidthFactor; 
@property(readwrite, nonatomic) CGFloat imageHeightFactor; 

@end

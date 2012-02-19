#import "GPUImageFilter.h"

@interface GPUImageSobelEdgeDetectionFilter : GPUImageFilter
{
    GLint intensityUniform, imageWidthFactorUniform, imageHeightFactorUniform;
}

// Intensity is the degree to which the edges are overlaid on the image. 1.0 is the default, and is complete visibility for them
@property(readwrite, nonatomic) CGFloat intensity; 
// The image width and height factors tweak the appearance of the edges. Normally, they are close to the image size in pixels
@property(readwrite, nonatomic) CGFloat imageWidthFactor; 
@property(readwrite, nonatomic) CGFloat imageHeightFactor; 

@end

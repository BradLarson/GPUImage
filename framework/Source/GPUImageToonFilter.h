#import "GPUImageFilter.h"

@interface GPUImageToonFilter : GPUImageFilter
{
    GLint imageWidthFactorUniform, imageHeightFactorUniform;
    GLint thresholdUniform, quantizationLevelsUniform;
    BOOL hasOverriddenImageSizeFactor;
}

// The image width and height factors tweak the appearance of the edges. By default, they match the filter size in pixels
@property(readwrite, nonatomic) CGFloat imageWidthFactor; 
@property(readwrite, nonatomic) CGFloat imageHeightFactor; 

// The threshold at which to apply the edges, default of 0.2
@property(readwrite, nonatomic) CGFloat threshold; 

// The levels of quantization for the posterization of colors within the scene, with a default of 10.0
@property(readwrite, nonatomic) CGFloat quantizationLevels; 

@end

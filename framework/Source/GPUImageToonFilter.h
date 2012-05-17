#import "GPUImage3x3TextureSamplingFilter.h"

@interface GPUImageToonFilter : GPUImage3x3TextureSamplingFilter
{
    GLint thresholdUniform, quantizationLevelsUniform;
}

// The threshold at which to apply the edges, default of 0.2
@property(readwrite, nonatomic) CGFloat threshold; 

// The levels of quantization for the posterization of colors within the scene, with a default of 10.0
@property(readwrite, nonatomic) CGFloat quantizationLevels; 

@end

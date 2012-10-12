#import "GPUImage3x3TextureSamplingFilter.h"

@interface GPUImageThresholdedNonMaximumSuppressionFilter : GPUImage3x3TextureSamplingFilter
{
    GLint thresholdUniform;
}

/** Any local maximum above this threshold will be white, and anything below black. Ranges from 0.0 to 1.0, with 0.8 as the default
 */
@property(readwrite, nonatomic) CGFloat threshold;

@end

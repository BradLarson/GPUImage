#import "GPUImageSobelEdgeDetectionFilter.h"

@interface GPUImageThresholdEdgeDetectionFilter : GPUImageSobelEdgeDetectionFilter
{
    GLint thresholdUniform;
}

/** Any edge above this threshold will be black, and anything below white. Ranges from 0.0 to 1.0, with 0.8 as the default
 */
@property(readwrite, nonatomic) CGFloat threshold; 

@end

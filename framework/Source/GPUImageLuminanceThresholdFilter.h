#import "GPUImageFilter.h"

/** Pixels with a luminance above the threshold will appear white, and those below will be black
 */
@interface GPUImageLuminanceThresholdFilter : GPUImageFilter
{
    GLint thresholdUniform;
}

/** Anything above this luminance will be white, and anything below black. Ranges from 0.0 to 1.0, with 0.5 as the default
 */
@property(readwrite, nonatomic) CGFloat threshold; 

@end


#import "GPUImageFilter.h"

@interface GPUImageHueFilter : GPUImageFilter
{
    GLint hueAdjustUniform;
    
}

// Hue ranges from -180.0 to 180.0, with 0.0 as the normal level
@property (nonatomic, readwrite) CGFloat hue;

@end

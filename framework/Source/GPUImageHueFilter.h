
#import "GPUImageFilter.h"

@interface GPUImageHueFilter : GPUImageFilter
{
    GLfloat hueAdjustUniform;
    
}
@property (nonatomic, readwrite) CGFloat hue;

@end

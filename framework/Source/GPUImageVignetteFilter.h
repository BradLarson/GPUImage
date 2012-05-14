#import "GPUImageFilter.h"

/** Performs a vignetting effect, fading out the image at the edges
 */
@interface GPUImageVignetteFilter : GPUImageFilter 
{
    GLint xUniform, yUniform;
}

/** The directional intensity of the vignette effect, with a default of x = 0.75, y = 0.5
 */
@property (nonatomic, readwrite) CGFloat x;
/** The directional intensity of the vignette effect, with a default of x = 0.75, y = 0.5
 */
@property (nonatomic, readwrite) CGFloat y;

@end

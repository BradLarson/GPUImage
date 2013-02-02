#import "GPUImageFilter.h"

/** Creates a pinch distortion of the image
 */
@interface GPUImagePinchDistortionFilter : GPUImageFilter
{
    GLint aspectRatioUniform, radiusUniform, centerUniform, scaleUniform;
}

/** The center about which to apply the distortion, with a default of (0.5, 0.5)
 */
@property(readwrite, nonatomic) CGPoint center;
/** The radius of the distortion, ranging from 0.0 to 2.0, with a default of 1.0
 */
@property(readwrite, nonatomic) CGFloat radius;
/** The amount of distortion to apply, from -2.0 to 2.0, with a default of 0.5
 */
@property(readwrite, nonatomic) CGFloat scale;

@end

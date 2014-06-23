#import "GPUImageFilter.h"

/** Creates a swirl distortion on the image
 */
@interface GPUImageSwirlFilter : GPUImageFilter
{
    GLint radiusUniform, centerUniform, angleUniform;
}

/// The center about which to apply the distortion, with a default of (0.5, 0.5)
@property(readwrite, nonatomic) CGPoint center;
/// The radius of the distortion, ranging from 0.0 to 1.0, with a default of 0.5
@property(readwrite, nonatomic) CGFloat radius;
/// The amount of distortion to apply, with a minimum of 0.0 and a default of 1.0
@property(readwrite, nonatomic) CGFloat angle;

@end

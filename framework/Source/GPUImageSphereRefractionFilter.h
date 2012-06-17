#import "GPUImageFilter.h"

@interface GPUImageSphereRefractionFilter : GPUImageFilter
{
    GLint radiusUniform, centerUniform, scaleUniform;
}

/// The center about which to apply the distortion, with a default of (0.5, 0.5)
@property(readwrite, nonatomic) CGPoint center;
/// The radius of the distortion, ranging from 0.0 to 1.0, with a default of 0.5
@property(readwrite, nonatomic) CGFloat radius;

@end

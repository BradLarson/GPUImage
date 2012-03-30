#import "GPUImageFilter.h"

@interface GPUImagePolarPixellateFilter : GPUImageFilter {
    GLint centerUniform, pixelSizeUniform;
}

// The center about which to apply the distortion, with a default of (0.5, 0.5)
@property(readwrite, nonatomic) CGPoint center;
// The amount of distortion to apply, from (-2.0, -2.0) to (2.0, 2.0), with a default of (0.05, 0.05)
@property(readwrite, nonatomic) CGSize pixelSize;


@end

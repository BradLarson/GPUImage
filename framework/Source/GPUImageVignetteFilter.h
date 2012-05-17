#import "GPUImageFilter.h"

@interface GPUImageVignetteFilter : GPUImageFilter 
{
    GLint vignetteStartUniform, vignetteEndUniform;
}

// The normalized distance from the center where the vignette effect starts. Default of 0.5.
@property (nonatomic, readwrite) CGFloat vignetteStart;

// The normalized distance from the center where the vignette effect ends. Default of 0.75.
@property (nonatomic, readwrite) CGFloat vignetteEnd;

@end

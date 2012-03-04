#import "GPUImageTwoPassFilter.h"

@interface GPUImageGaussianBlurFilter : GPUImageTwoPassFilter {
    GLint horizontalGaussianArrayUniform,
        horizontalBlurSizeUniform,
        verticalGaussianArrayUniform,
        verticalBlurSizeUniform;
}

@property (readwrite, nonatomic) CGFloat blurSize;

- (void) setGaussianValues;

@end

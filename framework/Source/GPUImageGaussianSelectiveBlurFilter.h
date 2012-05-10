#import "GPUImageGaussianBlurFilter.h"

@interface GPUImageGaussianSelectiveBlurFilter : GPUImageGaussianBlurFilter {
    GLint verticalExcludeCircleRadiusUniform,
    verticalExcludeCirclePointUniform,
    verticalExcludeCircleBlurSizeUniform,
    blurColorUniform;
    
    GLuint originalInputImageTexture;
}

@property (readwrite, nonatomic) CGFloat excludeCircleRadius;
@property (readwrite, nonatomic) CGPoint excludeCirclePoint;
@property (readwrite, nonatomic) CGFloat excludeBlurSize;
@property (readwrite, nonatomic) CGFloat blurColor;

@end
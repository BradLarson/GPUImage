#import "GPUImageFilter.h"

@interface GPUImageGaussianBlurFilter : GPUImageFilter {
    GPUImageFilter *horizontalBlur;
    GPUImageFilter *verticalBlur;
}

- (id) initWithGaussianVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;

@property (readwrite, nonatomic) CGFloat blurSize;

- (void) setGaussianValues;

@end

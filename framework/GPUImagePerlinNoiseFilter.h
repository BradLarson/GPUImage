#import "GPUImageFilter.h"

@interface GPUImagePerlinNoiseFilter : GPUImageFilter 
{
    GLint scaleUniform, colorStartUniform, colorFinishUniform;
}

@property (readwrite, nonatomic) GPUVector4 colorStart;
@property (readwrite, nonatomic) GPUVector4 colorFinish;

@property (readwrite, nonatomic) float scale;

@end

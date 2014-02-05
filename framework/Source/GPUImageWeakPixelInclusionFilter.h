#import "GPUImage3x3TextureSamplingFilter.h"

@interface GPUImageWeakPixelInclusionFilter : GPUImage3x3TextureSamplingFilter
{
    GLint fillColorUniform, pixelColorUniform;
}


@property(readwrite, nonatomic) GPUVector4 fillColor;
@property(readwrite, nonatomic) GPUVector4 pixelColor;

@end

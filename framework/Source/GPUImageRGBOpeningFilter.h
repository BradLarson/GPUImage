#import "GPUImageFilterGroup.h"

@class GPUImageRGBErosionFilter;
@class GPUImageRGBDilationFilter;

// A filter that first performs an erosion on each color channel of an image, followed by a dilation of the same radius. 
// This helps to filter out smaller bright elements.

@interface GPUImageRGBOpeningFilter : GPUImageFilterGroup
{
    GPUImageRGBErosionFilter *erosionFilter;
    GPUImageRGBDilationFilter *dilationFilter;
}

- (id)initWithRadius:(NSUInteger)radius;

@end

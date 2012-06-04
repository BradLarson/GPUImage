#import "GPUImageFilterGroup.h"

@class GPUImageRGBErosionFilter;
@class GPUImageRGBDilationFilter;

// A filter that first performs a dilation on each color channel of an image, followed by an erosion of the same radius. 
// This helps to filter out smaller dark elements.

@interface GPUImageRGBClosingFilter : GPUImageFilterGroup
{
    GPUImageRGBErosionFilter *erosionFilter;
    GPUImageRGBDilationFilter *dilationFilter;
}

- (id)initWithRadius:(NSUInteger)radius;


@end

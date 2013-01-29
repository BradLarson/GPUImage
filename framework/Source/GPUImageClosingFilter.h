#import "GPUImageFilterGroup.h"

@class GPUImageErosionFilter;
@class GPUImageDilationFilter;

// A filter that first performs a dilation on the red channel of an image, followed by an erosion of the same radius. 
// This helps to filter out smaller dark elements.

@interface GPUImageClosingFilter : GPUImageFilterGroup
{
    GPUImageErosionFilter *erosionFilter;
    GPUImageDilationFilter *dilationFilter;
}

- (id)initWithRadius:(NSUInteger)radius;

@end

#import "GPUImageTwoPassTextureSamplingFilter.h"

// For each pixel, this sets it to the minimum value of each color channel in a rectangular neighborhood extending out dilationRadius pixels from the center.
// This extends out dark features, and can be used for abstraction of color images.

@interface GPUImageRGBErosionFilter : GPUImageTwoPassTextureSamplingFilter

// Acceptable values for erosionRadius, which sets the distance in pixels to sample out from the center, are 1, 2, 3, and 4.
- (id)initWithRadius:(NSUInteger)erosionRadius;

@end

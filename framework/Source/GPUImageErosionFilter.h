#import "GPUImageTwoPassTextureSamplingFilter.h"

// For each pixel, this sets it to the minimum value of the red channel in a rectangular neighborhood extending out dilationRadius pixels from the center.
// This extends out dark features, and is most commonly used with black-and-white thresholded images.

@interface GPUImageErosionFilter : GPUImageTwoPassTextureSamplingFilter

// Acceptable values for erosionRadius, which sets the distance in pixels to sample out from the center, are 1, 2, 3, and 4.
- (id)initWithRadius:(NSUInteger)erosionRadius;

@end

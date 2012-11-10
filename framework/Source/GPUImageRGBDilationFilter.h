#import "GPUImageTwoPassTextureSamplingFilter.h"

// For each pixel, this sets it to the maximum value of each color channel in a rectangular neighborhood extending out dilationRadius pixels from the center.
// This extends out brighter colors, and can be used for abstraction of color images.

@interface GPUImageRGBDilationFilter : GPUImageTwoPassTextureSamplingFilter

// Acceptable values for dilationRadius, which sets the distance in pixels to sample out from the center, are 1, 2, 3, and 4.
- (id)initWithRadius:(NSUInteger)dilationRadius;

@end

#import "GPUImageTwoPassTextureSamplingFilter.h"

// For each pixel, this sets it to the maximum value of the red channel in a rectangular neighborhood extending out dilationRadius pixels from the center.
// This extends out bright features, and is most commonly used with black-and-white thresholded images.

extern NSString *const kGPUImageDilationRadiusOneVertexShaderString;
extern NSString *const kGPUImageDilationRadiusTwoVertexShaderString;
extern NSString *const kGPUImageDilationRadiusThreeVertexShaderString;
extern NSString *const kGPUImageDilationRadiusFourVertexShaderString;

@interface GPUImageDilationFilter : GPUImageTwoPassTextureSamplingFilter

// Acceptable values for dilationRadius, which sets the distance in pixels to sample out from the center, are 1, 2, 3, and 4.
- (id)initWithRadius:(NSUInteger)dilationRadius;

@end

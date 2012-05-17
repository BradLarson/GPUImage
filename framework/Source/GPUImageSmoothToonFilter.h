#import "GPUImageFilterGroup.h"

@class GPUImageGaussianBlurFilter;
@class GPUImageToonFilter;

/** This uses a similar process as the GPUImageToonFilter, only it precedes the toon effect with a Gaussian blur to smooth out noise.
 */
@interface GPUImageSmoothToonFilter : GPUImageFilterGroup
{
    GPUImageGaussianBlurFilter *blurFilter;
    GPUImageToonFilter *toonFilter;
}

/// The image width and height factors tweak the appearance of the edges. By default, they match the filter size in pixels
@property(readwrite, nonatomic) CGFloat texelWidth; 
/// The image width and height factors tweak the appearance of the edges. By default, they match the filter size in pixels
@property(readwrite, nonatomic) CGFloat texelHeight; 

/// A multiplier for the blur size, ranging from 0.0 on up, with a default of 0.5
@property (readwrite, nonatomic) CGFloat blurSize;

/// The threshold at which to apply the edges, default of 0.2
@property(readwrite, nonatomic) CGFloat threshold; 

/// The levels of quantization for the posterization of colors within the scene, with a default of 10.0
@property(readwrite, nonatomic) CGFloat quantizationLevels; 

@end

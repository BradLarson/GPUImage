#import "GPUImageTwoPassTextureSamplingFilter.h"

/** A hardware-accelerated 9-hit box blur of an image
 */
@interface GPUImageBoxBlurFilter : GPUImageTwoPassTextureSamplingFilter

/// A scaling for the size of the applied blur, default of 1.0
@property(readwrite, nonatomic) CGFloat blurSize;

@end

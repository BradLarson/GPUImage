#import "GPUImageTwoPassTextureSamplingFilter.h"

/** A Gaussian blur filter
    Interpolated optimization based on Daniel Rákos' work at http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
 */

@interface GPUImageGaussianBlurFilter : GPUImageTwoPassTextureSamplingFilter 
{
    BOOL shouldResizeBlurRadiusWithImageSize;
    CGFloat _blurRadiusInPixels;
}

/** A multiplier for the blur size, ranging from 0.0 on up, with a default of 1.0
 */
@property (readwrite, nonatomic) CGFloat blurSize;

/** A radius in pixels (in 0.5 pixel increments) to use for the blur, with a default of 2.0
 */
@property (readwrite, nonatomic) CGFloat blurRadiusInPixels;

/** Setting these properties will allow the blur radius to scale with the size of the image
 */
@property (readwrite, nonatomic) CGFloat blurRadiusAsFractionOfImageWidth;
@property (readwrite, nonatomic) CGFloat blurRadiusAsFractionOfImageHeight;

/// The number of times to sequentially blur the incoming image. The more passes, the slower the filter.
@property(readwrite, nonatomic) NSUInteger blurPasses;

+ (NSString *)vertexShaderForStandardBlurOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma;
+ (NSString *)fragmentShaderForStandardBlurOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma;
+ (NSString *)vertexShaderForOptimizedBlurOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma;
+ (NSString *)fragmentShaderForOptimizedBlurOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma;

- (void)switchToVertexShader:(NSString *)newVertexShader fragmentShader:(NSString *)newFragmentShader;

@end

#import "GPUImageFilterGroup.h"

@class GPUImageGrayscaleFilter;
@class GPUImageSingleComponentFastBlurFilter;
@class GPUimageDirectionalSobelEdgeDetectionFilter;
@class GPUImageDirectionalNonMaximumSuppressionFilter;
@class GPUImageWeakPixelInclusionFilter;

/** This uses a Gaussian blur, followed by applying a Sobel operator, then a thresholding operation, in order to highlight edges
 */
@interface GPUImageCannyEdgeDetectionFilter : GPUImageFilterGroup
{
    GPUImageGrayscaleFilter *luminanceFilter;
    GPUImageSingleComponentFastBlurFilter *blurFilter;
    GPUimageDirectionalSobelEdgeDetectionFilter *edgeDetectionFilter;
    GPUImageDirectionalNonMaximumSuppressionFilter *nonMaximumSuppressionFilter;
    GPUImageWeakPixelInclusionFilter *weakPixelInclusionFilter;
}

/** The image width and height factors tweak the appearance of the edges.
 
 These parameters affect the visibility of the detected edges
 
 By default, they match the inverse of the filter size in pixels
 */
@property(readwrite, nonatomic) CGFloat texelWidth; 
/** The image width and height factors tweak the appearance of the edges.
 
 These parameters affect the visibility of the detected edges
 
 By default, they match the inverse of the filter size in pixels
 */
@property(readwrite, nonatomic) CGFloat texelHeight; 

/** A multiplier for the blur size, ranging from 0.0 on up, with a default of 1.0
 */
@property (readwrite, nonatomic) CGFloat blurSize;

/** Any edge with a gradient magnitude above this threshold will pass and show up in the final result.
 */
@property(readwrite, nonatomic) CGFloat upperThreshold; 

/** Any edge with a gradient magnitude below this threshold will fail and be removed from the final result.
 */
@property(readwrite, nonatomic) CGFloat lowerThreshold; 

@end

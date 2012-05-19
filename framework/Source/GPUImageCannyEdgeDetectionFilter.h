#import "GPUImageFilterGroup.h"

@class GPUImageGaussianBlurFilter;
@class GPUImageThresholdEdgeDetection;
@class GPUImageSketchFilter;

/** This uses a Gaussian blur before applying a Sobel operator to highlight edges
 */
@interface GPUImageCannyEdgeDetectionFilter : GPUImageFilterGroup
{
    GPUImageGaussianBlurFilter *blurFilter;
    GPUImageThresholdEdgeDetection *edgeDetectionFilter;
//    GPUImageSketchFilter *edgeDetectionFilter;
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

/** Any edge above this threshold will be black, and anything below white. Ranges from 0.0 to 1.0, with 0.5 as the default
 */
@property(readwrite, nonatomic) CGFloat threshold; 

@end

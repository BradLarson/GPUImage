#import "GPUImageSobelEdgeDetectionFilter.h"

/** Converts video to look like a sketch.
 
 This is just the Sobel edge detection filter with the colors inverted.
 */
@interface GPUImageSketchFilter : GPUImageSobelEdgeDetectionFilter
{
}

@end

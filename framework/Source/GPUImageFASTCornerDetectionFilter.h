#import "GPUImageFilterGroup.h"

@class GPUImageGrayscaleFilter;
@class GPUImage3x3TextureSamplingFilter;
@class GPUImageNonMaximumSuppressionFilter;

/* 
 An implementation of the Features from Accelerated Segment Test (FAST) feature detector as described in the following publications:
 
 E. Rosten and T. Drummond. Fusing points and lines for high performance tracking. IEEE International Conference on Computer Vision, 2005.
 E. Rosten and T. Drummond. Machine learning for high-speed corner detection.  European Conference on Computer Vision, 2006.
 
 For more about the FAST feature detector, see the resources here:
 http://www.edwardrosten.com/work/fast.html
 */

typedef enum { kGPUImageFAST12Contiguous, kGPUImageFAST12ContiguousNonMaximumSuppressed} GPUImageFASTDetectorType;

@interface GPUImageFASTCornerDetectionFilter : GPUImageFilterGroup
{
    GPUImageGrayscaleFilter *luminanceReductionFilter;
    GPUImage3x3TextureSamplingFilter *featureDetectionFilter;
    GPUImageNonMaximumSuppressionFilter *nonMaximumSuppressionFilter;
// Generate a lookup texture based on the bit patterns
    
// Step 1: convert to monochrome if necessary
// Step 2: do a lookup at each pixel based on the Bresenham circle, encode comparison in two color components
// Step 3: do non-maximum suppression of close corner points
}

- (id)initWithFASTDetectorVariant:(GPUImageFASTDetectorType)detectorType;

@end

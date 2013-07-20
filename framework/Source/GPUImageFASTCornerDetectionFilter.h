#import "GPUImageFilterGroup.h"

@interface GPUImageFASTCornerDetectionFilter : GPUImageFilterGroup
{
// Generate a lookup texture based on the bit patterns
    
// Step 1: convert to monochrome if necessary
// Step 2: do a lookup at each pixel based on the Bresenham circle, encode comparison in two color components
// Step 3: do non-maximum suppression of close corner points
}
@end

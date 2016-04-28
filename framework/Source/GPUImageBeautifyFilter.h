#import "GPUImageFilterGroup.h"

@class GPUImageBilateralFilter;
@class GPUImageCannyEdgeDetectionFilter;
@class GPUImageCombinationFilter;
@class GPUImageHSBFilter;

@interface GPUImageBeautifyFilter : GPUImageFilterGroup {
    GPUImageBilateralFilter *bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter;
    GPUImageCombinationFilter *combinationFilter;
    GPUImageHSBFilter *hsbFilter;
}

@end

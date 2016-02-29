#import "GPUImageFilterGroup.h"

// This generates image-wide feature descriptors using the ColourFAST process, as developed and described in
//
// A. Ensor and S. Hall. ColourFAST: GPU-based feature point detection and tracking on mobile devices. 28th International Conference of Image and Vision Computing, New Zealand, 2013, p. 124-129.
//
// Seth Hall, "GPU accelerated feature algorithms for mobile devices", PhD thesis, School of Computing and Mathematical Sciences, Auckland University of Technology 2014.
// http://aut.researchgateway.ac.nz/handle/10292/7991

@class GPUImageColourFASTSamplingOperation;
@class GPUImageBoxBlurFilter;

@interface GPUImageColourFASTFeatureDetector : GPUImageFilterGroup
{
    GPUImageBoxBlurFilter *blurFilter;
    GPUImageColourFASTSamplingOperation *colourFASTSamplingOperation;
}
// The blur radius of the underlying box blur. The default is 3.0.
@property (readwrite, nonatomic) CGFloat blurRadiusInPixels;

@end

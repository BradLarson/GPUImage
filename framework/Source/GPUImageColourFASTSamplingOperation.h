#import "GPUImageTwoInputFilter.h"

// This is the feature extraction phase of the ColourFAST feature detector, as described in:
//
// A. Ensor and S. Hall. ColourFAST: GPU-based feature point detection and tracking on mobile devices. 28th International Conference of Image and Vision Computing, New Zealand, 2013, p. 124-129.
//
// Seth Hall, "GPU accelerated feature algorithms for mobile devices", PhD thesis, School of Computing and Mathematical Sciences, Auckland University of Technology 2014.
// http://aut.researchgateway.ac.nz/handle/10292/7991

@interface GPUImageColourFASTSamplingOperation : GPUImageTwoInputFilter
{
    GLint texelWidthUniform, texelHeightUniform;
    
    CGFloat texelWidth, texelHeight;
    BOOL hasOverriddenImageSizeFactor;
}

// The texel width and height determines how far out to sample from this texel. By default, this is the normalized width of a pixel, but this can be overridden for different effects.
@property(readwrite, nonatomic) CGFloat texelWidth;
@property(readwrite, nonatomic) CGFloat texelHeight;

@end

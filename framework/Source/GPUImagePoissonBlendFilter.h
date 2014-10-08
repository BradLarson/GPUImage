#import "GPUImageTwoInputCrossTextureSamplingFilter.h"
#import "GPUImageFilterGroup.h"

@interface GPUImagePoissonBlendFilter : GPUImageTwoInputCrossTextureSamplingFilter
{
    GLint mixUniform;
    
    GPUImageFramebuffer *secondOutputFramebuffer;
}

// Mix ranges from 0.0 (only image 1) to 1.0 (only image 2 gradients), with 1.0 as the normal level
@property(readwrite, nonatomic) CGFloat mix;

// The number of times to propagate the gradients.
// Crank this up to 100 or even 1000 if you want to get anywhere near convergence.  Yes, this will be slow.
@property(readwrite, nonatomic) NSUInteger numIterations;

@end
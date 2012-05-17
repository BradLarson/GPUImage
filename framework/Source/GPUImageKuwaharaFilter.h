#import "GPUImageFilter.h"

/** Kuwahara image abstraction, drawn from the work of Kyprianidis, et. al. in their publication "Anisotropic Kuwahara Filtering on the GPU" within the GPU Pro collection. This produces an oil-painting-like image, but it is extremely computationally expensive, so it can take seconds to render a frame on an iPad 2. This might be best used for still images.
 */
@interface GPUImageKuwaharaFilter : GPUImageFilter
{
    GLint radiusUniform;
}

/// The radius to sample from when creating the brush-stroke effect, with a default of 3. The larger the radius, the slower the filter.
@property(readwrite, nonatomic) GLuint radius;

@end

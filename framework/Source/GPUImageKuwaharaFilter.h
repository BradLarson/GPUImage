#import "GPUImageFilter.h"

@interface GPUImageKuwaharaFilter : GPUImageFilter
{
    GLint radiusUniform;
}

// The radius to sample from when creating the brush-stroke effect, with a default of 3. The larger the radius, the slower the filter.
@property(readwrite, nonatomic) GLuint radius;

@end

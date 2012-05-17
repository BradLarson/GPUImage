#import "GPUImageFilter.h"

@interface GPUImagePosterizeFilter : GPUImageFilter
{
    GLint colorLevelsUniform;
}

// The number of color levels to reduce the image space to. This ranges from 1 to 256, with a default of 10.
@property(readwrite, nonatomic) NSUInteger colorLevels; 

@end

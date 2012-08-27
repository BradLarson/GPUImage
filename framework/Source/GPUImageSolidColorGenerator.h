#import "GPUImageFilter.h"

// This outputs an image with a constant color. You need to use -forceProcessingAtSize: in order to set the output image
// dimensions, or this won't work correctly


@interface GPUImageSolidColorGenerator : GPUImageFilter
{
    GLint colorUniform;
}

// This color dictates what the output image will be filled with
@property(readwrite, nonatomic) GPUVector4 color;

- (void)setColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;

@end

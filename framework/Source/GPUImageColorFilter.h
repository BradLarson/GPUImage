#import "GPUImageFilter.h"

@interface GPUImageColorFilter : GPUImageFilter
{
    GLint filterColorUniform;
}

@property(readwrite, nonatomic) GPUVector4 color;

- (void)setColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;

@end

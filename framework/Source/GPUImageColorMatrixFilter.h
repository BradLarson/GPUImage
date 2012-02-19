#import "GPUImageFilter.h"

struct GPUVector4 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
    GLfloat four;
};
typedef struct GPUVector4 GPUVector4;

struct GPUMatrix4x4 {
    GPUVector4 one;
    GPUVector4 two;
    GPUVector4 three;
    GPUVector4 four;
};
typedef struct GPUMatrix4x4 GPUMatrix4x4;

@interface GPUImageColorMatrixFilter : GPUImageFilter
{
    GLint colorMatrixUniform;
    GLint intensityUniform;
}

@property(readwrite, nonatomic) GPUMatrix4x4 colorMatrix;
@property(readwrite, nonatomic) CGFloat intensity;

@end

#import "GPUImageFilter.h"

@interface GPUImageTransformFilter : GPUImageFilter
{
    GLint transformMatrixUniform;
}

// You can either set the transform to apply to be a 2-D affine transform or a 3-D transform. The default is the identity transform (the output image is identical to the input).
@property(readwrite, nonatomic) CGAffineTransform affineTransform;
@property(readwrite, nonatomic) CATransform3D transform3D;

@end

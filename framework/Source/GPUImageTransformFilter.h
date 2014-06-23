#import "GPUImageFilter.h"

@interface GPUImageTransformFilter : GPUImageFilter
{
    GLint transformMatrixUniform, orthographicMatrixUniform;
    GPUMatrix4x4 orthographicMatrix;
}

// You can either set the transform to apply to be a 2-D affine transform or a 3-D transform. The default is the identity transform (the output image is identical to the input).
@property(readwrite, nonatomic) CGAffineTransform affineTransform;
@property(readwrite, nonatomic) CATransform3D transform3D;

// This applies the transform to the raw frame data if set to YES, the default of NO takes the aspect ratio of the image input into account when rotating
@property(readwrite, nonatomic) BOOL ignoreAspectRatio;

// sets the anchor point to top left corner
@property(readwrite, nonatomic) BOOL anchorTopLeft;

@end

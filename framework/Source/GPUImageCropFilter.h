#import "GPUImageFilter.h"

@interface GPUImageCropFilter : GPUImageFilter
{
    GLfloat cropTextureCoordinates[8];
}

// The crop region is the rectangle within the image to crop. It is normalized to a coordinate space from 0.0 to 1.0, with 0.0, 0.0 being the upper left corner of the image
@property(readwrite, nonatomic) CGRect cropRegion;

// Initialization and teardown
- (id)initWithCropRegion:(CGRect)newCropRegion;

@end

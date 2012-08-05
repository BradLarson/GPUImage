#import "GPUImageFilter.h"

@interface GPUImageRGBFilter : GPUImageFilter
{
    GLint redUniform;
    GLint greenUniform;
    GLint blueUniform;
}

// Normalized values by which each color channel is multiplied. The range is from 0.0 up, with 1.0 as the default.
@property (readwrite, nonatomic) CGFloat red; 
@property (readwrite, nonatomic) CGFloat green; 
@property (readwrite, nonatomic) CGFloat blue;

@end

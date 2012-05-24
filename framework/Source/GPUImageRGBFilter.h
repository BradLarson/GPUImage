#import "GPUImageFilter.h"

@interface GPUImageRGBFilter : GPUImageFilter
{
    GLint redUniform;
    GLint greenUniform;
    GLint blueUniform;
}

@property (readwrite, nonatomic) CGFloat red; 
@property (readwrite, nonatomic) CGFloat green; 
@property (readwrite, nonatomic) CGFloat blue;

@end
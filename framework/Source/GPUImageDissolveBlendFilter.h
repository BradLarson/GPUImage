#import "GPUImageTwoInputFilter.h"

@interface GPUImageDissolveBlendFilter : GPUImageTwoInputFilter
{
    GLint mixUniform;
}

// Mix ranges from 0.0 (only image 1) to 1.0 (only image 2), with 0.5 (half of either) as the normal level
@property(readwrite, nonatomic) CGFloat mix; 

@end

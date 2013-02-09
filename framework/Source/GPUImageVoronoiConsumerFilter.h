#import "GPUImageTwoInputFilter.h"

@interface GPUImageVoronoiConsumerFilter : GPUImageTwoInputFilter 
{
    GLint sizeUniform;
}

@property (nonatomic, readwrite) CGSize sizeInPixels;

@end

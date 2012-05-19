#import "GPUImageTwoInputFilter.h"

@interface GPUImageVoroniConsumerFilter : GPUImageTwoInputFilter 
{
    GLint sizeUniform;
}

@property (nonatomic, readwrite) CGSize sizeInPixels;

@end

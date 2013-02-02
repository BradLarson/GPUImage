#import "GPUImageFilter.h"

@interface GPUImageBuffer : GPUImageFilter
{
    NSMutableArray *bufferedTextures;
}

@property(readwrite, nonatomic) NSUInteger bufferSize;

@end

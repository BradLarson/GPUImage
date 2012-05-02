#import "GPUImageTextureInput.h"

@implementation GPUImageTextureInput

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithTexture:(GLuint)newInputTexture size:(CGSize)newTextureSize;
{
    if (!(self = [super init]))
    {
        return nil;
    }

    [self deleteOutputTexture];
    
    outputTexture = newInputTexture;
    textureSize = newTextureSize;
    
    return self;
}

#pragma mark -
#pragma mark Image rendering

- (void)processTexture;
{
    for (id<GPUImageInput> currentTarget in targets)
    {
        [currentTarget setInputSize:textureSize];
        [currentTarget newFrameReadyAtTime:kCMTimeInvalid];
    }
}

@end

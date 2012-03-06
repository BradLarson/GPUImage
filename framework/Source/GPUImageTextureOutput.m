#import "GPUImageTextureOutput.h"

@implementation GPUImageTextureOutput

@synthesize delegate = _delegate;
@synthesize texture = _texture;

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReady;
{
    [_delegate newFrameReadyFromTextureOutput:self];
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputTexture:(GLuint)newInputTexture atIndex:(NSInteger)textureIndex;
{
    _texture = newInputTexture;
}

- (void)setInputSize:(CGSize)newSize;
{
}

- (CGSize)maximumOutputSize;
{
    return CGSizeZero;
}

@end

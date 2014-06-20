#import "GPUImageBuffer.h"

@interface GPUImageBuffer()

@end

@implementation GPUImageBuffer

@synthesize bufferSize = _bufferSize;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kGPUImagePassthroughFragmentShaderString]))
    {
        return nil;
    }
    
    bufferedFramebuffers = [[NSMutableArray alloc] init];
//    [bufferedTextures addObject:[NSNumber numberWithInt:outputTexture]];
    _bufferSize = 1;
    
    return self;
}

- (void)dealloc
{
    for (GPUImageFramebuffer *currentFramebuffer in bufferedFramebuffers)
    {
        [currentFramebuffer unlock];
    }
}

#pragma mark -
#pragma mark GPUImageInput

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    if ([bufferedFramebuffers count] >= _bufferSize)
    {
        outputFramebuffer = [bufferedFramebuffers objectAtIndex:0];
        [bufferedFramebuffers removeObjectAtIndex:0];
    }
    else
    {
        // Nothing yet in the buffer, so don't process further until the buffer is full
        outputFramebuffer = firstInputFramebuffer;
        [firstInputFramebuffer lock];
    }
    
    [bufferedFramebuffers addObject:firstInputFramebuffer];

    // Need to pass along rotation information, as we're just holding on to buffered framebuffers and not rotating them ourselves
    for (id<GPUImageInput> currentTarget in targets)
    {
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [currentTarget setInputRotation:inputRotation atIndex:textureIndex];
        }
    }

    // Let the downstream video elements see the previous frame from the buffer before rendering a new one into place
    [self informTargetsAboutNewFrameAtTime:frameTime];
 
//    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    // No need to render to another texture anymore, since we'll be hanging on to the textures in our buffer
}

#pragma mark -
#pragma mark Accessors

- (void)setBufferSize:(NSUInteger)newValue;
{
    if ( (newValue == _bufferSize) || (newValue < 1) )
    {
        return;
    }
        
    if (newValue > _bufferSize)
    {
        NSUInteger texturesToAdd = newValue - _bufferSize;
        for (NSUInteger currentTextureIndex = 0; currentTextureIndex < texturesToAdd; currentTextureIndex++)
        {
            // TODO: Deal with the growth of the size of the buffer by rotating framebuffers, no textures
        }
    }
    else
    {
        NSUInteger texturesToRemove = _bufferSize - newValue;
        for (NSUInteger currentTextureIndex = 0; currentTextureIndex < texturesToRemove; currentTextureIndex++)
        {
            GPUImageFramebuffer *lastFramebuffer = [bufferedFramebuffers lastObject];
            [bufferedFramebuffers removeObjectAtIndex:([bufferedFramebuffers count] - 1)];
            
            [lastFramebuffer unlock];
            lastFramebuffer = nil;
        }
    }

  _bufferSize = newValue;
}

@end

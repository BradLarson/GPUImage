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
    static const GLfloat imageVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    [self notifyTargetsAboutNewOutputTexture];

    // Let the downstream video elements see the previous frame from the buffer before rendering a new one into place
    [self informTargetsAboutNewFrameAtTime:frameTime];
    
    // Move the last frame to the back of the buffer, if needed
    if (_bufferSize > 1)
    {
        NSNumber *lastFramebuffer = [bufferedFramebuffers objectAtIndex:0];
        [bufferedFramebuffers removeObjectAtIndex:0];
        [bufferedFramebuffers addObject:lastFramebuffer];
    }
    else
    {
        // Make sure the previous rendering has finished before enqueuing the current frame when simply delaying by one frame
        glFinish();
    }    
    
    // Render the new frame to the back of the buffer
    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    [GPUImageContext setActiveShaderProgram:filterProgram];
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    [bufferedFramebuffers addObject:outputFramebuffer];
    // TODO: Instead of redrawing these into textures, capture the incoming framebuffer and prevent it from returning to the pool
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
	
	glUniform1i(filterInputTextureUniform, 2);	
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
	glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [firstInputFramebuffer unlock];
}

#pragma mark -
#pragma mark Managing targets

- (GPUImageFramebuffer *)framebufferForOutput;
{
    return [bufferedFramebuffers objectAtIndex:0];
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

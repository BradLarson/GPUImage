#import "GPUImageBuffer.h"

@interface GPUImageBuffer()

//Texture management
- (GLuint)generateTexture;
- (void)removeTexture:(GLuint)textureToRemove;

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
    
    bufferedTextures = [[NSMutableArray alloc] init];
    [self initializeOutputTextureIfNeeded];
    [bufferedTextures addObject:[NSNumber numberWithInt:outputTexture]];
    _bufferSize = 1;
    
    return self;
}

- (void)dealloc
{
    for (NSNumber *currentTextureName in bufferedTextures)
    {
        [self removeTexture:[currentTextureName intValue]];
    }
}

#pragma mark -
#pragma mark GPUImageInput

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    outputTextureRetainCount = [targets count];

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
        NSNumber *lastTextureName = [bufferedTextures objectAtIndex:0];
        [bufferedTextures removeObjectAtIndex:0];
        [bufferedTextures addObject:lastTextureName];
    }
    else
    {
        // Make sure the previous rendering has finished before enqueuing the current frame when simply delaying by one frame
        glFinish();
    }    
    
    // Render the new frame to the back of the buffer
    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation] sourceTexture:filterSourceTexture];
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    if (self.preventRendering)
    {
        return;
    }
    
    [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
    [self setFilterFBO];
    
    glBindTexture(GL_TEXTURE_2D, [[bufferedTextures lastObject] intValue]);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, [[bufferedTextures lastObject] intValue], 0);
        
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, sourceTexture);
	
	glUniform1i(filterInputTextureUniform, 2);	
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
	glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);    
}

- (void)prepareForImageCapture;
{
    // Disable this for now, until I figure out how to integrate the texture caches with a buffer like this
}

#pragma mark -
#pragma mark Managing targets

- (GLuint)textureForOutput;
{
    return [[bufferedTextures objectAtIndex:0] intValue];
}

#pragma mark -
#pragma mark Texture management

- (GLuint)generateTexture;
{
    GLuint newTextureName = 0;
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &newTextureName);
	glBindTexture(GL_TEXTURE_2D, newTextureName);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// This is necessary for non-power-of-two textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    CGSize currentFBOSize = [self sizeOfFBO];
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)currentFBOSize.width, (int)currentFBOSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    glBindTexture(GL_TEXTURE_2D, 0);

    return newTextureName;
}

- (void)removeTexture:(GLuint)textureToRemove;
{
    glDeleteTextures(1, &textureToRemove);
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
            [bufferedTextures addObject:[NSNumber numberWithInt:[self generateTexture]]];
        }
    }
    else
    {
        NSUInteger texturesToRemove = _bufferSize - newValue;
        for (NSUInteger currentTextureIndex = 0; currentTextureIndex < texturesToRemove; currentTextureIndex++)
        {
            NSNumber *lastTextureName = [bufferedTextures lastObject];
            [bufferedTextures removeObjectAtIndex:([bufferedTextures count] - 1)];
            [self removeTexture:[lastTextureName intValue]];
        }
    }

  _bufferSize = newValue;
}

@end

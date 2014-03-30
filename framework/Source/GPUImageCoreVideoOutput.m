#import "GPUImageCoreVideoOutput.h"

#import "GPUImageContext.h"
#import "GLProgram.h"
#import "GPUImageFilter.h"

NSString *const kGPUImageColorSwizzlingFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate).bgra;
 }
 );


@interface GPUImageCoreVideoOutput ()
{
    GLuint movieFramebuffer, movieRenderbuffer;
    
    GLProgram *colorSwizzlingProgram;
    GLint colorSwizzlingPositionAttribute, colorSwizzlingTextureCoordinateAttribute;
    GLint colorSwizzlingInputTextureUniform;

    GPUImageFramebuffer *firstInputFramebuffer;
}

// Frame rendering
- (void)createDataFBO;
- (void)destroyDataFBO;
- (void)setFilterFBO;

- (void)renderAtInternalSize;

@end

@implementation GPUImageCoreVideoOutput

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithVideoSize:(CGSize)newSize
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    self.enabled = YES;
    
    videoSize = newSize;
    inputRotation = kGPUImageNoRotation;
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        if ([GPUImageContext supportsFastTextureUpload])
        {
            colorSwizzlingProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
        }
        else
        {
            colorSwizzlingProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageColorSwizzlingFragmentShaderString];
        }
        
        if (!colorSwizzlingProgram.initialized)
        {
            [colorSwizzlingProgram addAttribute:@"position"];
            [colorSwizzlingProgram addAttribute:@"inputTextureCoordinate"];
            
            if (![colorSwizzlingProgram link])
            {
                NSString *progLog = [colorSwizzlingProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [colorSwizzlingProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [colorSwizzlingProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                colorSwizzlingProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        
        colorSwizzlingPositionAttribute = [colorSwizzlingProgram attributeIndex:@"position"];
        colorSwizzlingTextureCoordinateAttribute = [colorSwizzlingProgram attributeIndex:@"inputTextureCoordinate"];
        colorSwizzlingInputTextureUniform = [colorSwizzlingProgram uniformIndex:@"inputImageTexture"];
        
        // REFACTOR: Wrap this in a block for the image processing queue
        [GPUImageContext setActiveShaderProgram:colorSwizzlingProgram];
        
        glEnableVertexAttribArray(colorSwizzlingPositionAttribute);
        glEnableVertexAttribArray(colorSwizzlingTextureCoordinateAttribute);
    });
    
    return self;
}

- (void)dealloc;
{
    [self destroyDataFBO];
}

#pragma mark -
#pragma mark Frame rendering

- (CVPixelBufferRef)createPixelBuffer
{
    NSAssert(NO, @"Must override createPixelBuffer");
    return NULL;
}

- (void)createDataFBO;
{
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &movieFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    
    if ([GPUImageContext supportsFastTextureUpload])
    {
#if defined(__IPHONE_6_0)
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[GPUImageContext sharedImageProcessingContext] context], NULL, &coreVideoTextureCache);
#else
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageContext sharedImageProcessingContext] context], NULL, &coreVideoTextureCache);
#endif
        
        if (err)
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
        
        // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
        
        renderTarget = [self createPixelBuffer];
        if (renderTarget) {
            [self bindRenderTarget:renderTarget];
        } else {
            /* The framebuffer is not yet complete so we bypass the completeness check */
            return;
        }
    }
    else
    {
        glGenRenderbuffers(1, &movieRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, movieRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, (int)videoSize.width, (int)videoSize.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, movieRenderbuffer);
    }
    
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}

- (void)bindRenderTarget:(CVPixelBufferRef)aRenderTarget
{
    if (!coreVideoTextureCache)
        return;
    
    if (renderTexture)
    {
        CFRelease(renderTexture);
        renderTexture = NULL;
    }
    
    CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, coreVideoTextureCache, aRenderTarget,
                                                  NULL, // texture attributes
                                                  GL_TEXTURE_2D,
                                                  GL_RGBA, // opengl format
                                                  (int)videoSize.width,
                                                  (int)videoSize.height,
                                                  GL_BGRA, // native iOS format
                                                  GL_UNSIGNED_BYTE,
                                                  0,
                                                  &renderTexture);
    
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}

- (void)destroyDataFBO;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        if (movieFramebuffer)
        {
            glDeleteFramebuffers(1, &movieFramebuffer);
            movieFramebuffer = 0;
        }
        
        if (movieRenderbuffer)
        {
            glDeleteRenderbuffers(1, &movieRenderbuffer);
            movieRenderbuffer = 0;
        }
        
        if ([GPUImageContext supportsFastTextureUpload])
        {
            if (coreVideoTextureCache)
            {
                CFRelease(coreVideoTextureCache);
                coreVideoTextureCache = NULL;
            }
            
            if (renderTexture)
            {
                CFRelease(renderTexture);
                renderTexture = NULL;
            }
            if (renderTarget)
            {
                CVPixelBufferRelease(renderTarget);
                renderTarget = NULL;
            }
            
        }
    });
}

- (void)setFilterFBO;
{
    if (!movieFramebuffer)
    {
        [self createDataFBO];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    
    glViewport(0, 0, (int)videoSize.width, (int)videoSize.height);
    
    CVPixelBufferRef renderTargetForFrame = [self renderTargetForFrame];
    if (renderTargetForFrame) {
        [self bindRenderTarget:renderTargetForFrame];
    }
}

/** Return a CVPixelBufferRef if we should use a specific CVPixelBufferRef for this
    frame, otherwise return NULL and the existing renderTarget will be used.
 */
- (CVPixelBufferRef)renderTargetForFrame
{
    return NULL;
}

- (void)renderAtInternalSize;
{
    [GPUImageContext useImageProcessingContext];
    [self setFilterFBO];
    
    [GPUImageContext setActiveShaderProgram:colorSwizzlingProgram];
    
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // This needs to be flipped to write out to video correctly
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    const GLfloat *textureCoordinates = [GPUImageFilter textureCoordinatesForRotation:inputRotation];
    
	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
	glUniform1i(colorSwizzlingInputTextureUniform, 4);	
    
    glVertexAttribPointer(colorSwizzlingPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
	glVertexAttribPointer(colorSwizzlingTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glFinish();
    [firstInputFramebuffer unlock];
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    // Render the frame with swizzled colors, so that they can be uploaded quickly as BGRA frames
    [GPUImageContext useImageProcessingContext];
    [self renderAtInternalSize];
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    firstInputFramebuffer = newInputFramebuffer;
    [firstInputFramebuffer lock];
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    inputRotation = newInputRotation;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
}

- (CGSize)maximumOutputSize;
{
    return videoSize;
}

- (void)endProcessing
{
    
}

- (BOOL)shouldIgnoreUpdatesToThisTarget;
{
    return NO;
}

- (BOOL)wantsMonochromeInput;
{
    return NO;
}

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
{
    
}

@end

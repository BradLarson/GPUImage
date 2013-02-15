#import "GPUImageTwoPassFilter.h"

@implementation GPUImageTwoPassFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithFirstStageVertexShaderFromString:(NSString *)firstStageVertexShaderString firstStageFragmentShaderFromString:(NSString *)firstStageFragmentShaderString secondStageVertexShaderFromString:(NSString *)secondStageVertexShaderString secondStageFragmentShaderFromString:(NSString *)secondStageFragmentShaderString;
{
    if (!(self = [super initWithVertexShaderFromString:firstStageVertexShaderString fragmentShaderFromString:firstStageFragmentShaderString]))
    {
		return nil;
    }
    
    secondProgramUniformStateRestorationBlocks = [NSMutableDictionary dictionaryWithCapacity:10];

    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext useImageProcessingContext];

        secondFilterProgram = [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] programForVertexShaderString:secondStageVertexShaderString fragmentShaderString:secondStageFragmentShaderString];
        
        if (!secondFilterProgram.initialized)
        {
            [self initializeSecondaryAttributes];
            
            if (![secondFilterProgram link])
            {
                NSString *progLog = [secondFilterProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [secondFilterProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [secondFilterProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                filterProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        
        secondFilterPositionAttribute = [secondFilterProgram attributeIndex:@"position"];
        secondFilterTextureCoordinateAttribute = [secondFilterProgram attributeIndex:@"inputTextureCoordinate"];
        secondFilterInputTextureUniform = [secondFilterProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
        secondFilterInputTextureUniform2 = [secondFilterProgram uniformIndex:@"inputImageTexture2"]; // This does assume a name of "inputImageTexture2" for second input texture in the fragment shader
        
        [GPUImageOpenGLESContext setActiveShaderProgram:secondFilterProgram];
        
        glEnableVertexAttribArray(secondFilterPositionAttribute);
        glEnableVertexAttribArray(secondFilterTextureCoordinateAttribute);
    });

    return self;
}

- (id)initWithFirstStageFragmentShaderFromString:(NSString *)firstStageFragmentShaderString secondStageFragmentShaderFromString:(NSString *)secondStageFragmentShaderString;
{
    if (!(self = [self initWithFirstStageVertexShaderFromString:kGPUImageVertexShaderString firstStageFragmentShaderFromString:firstStageFragmentShaderString secondStageVertexShaderFromString:kGPUImageVertexShaderString secondStageFragmentShaderFromString:secondStageFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

- (void)initializeSecondaryAttributes;
{
    [secondFilterProgram addAttribute:@"position"];
	[secondFilterProgram addAttribute:@"inputTextureCoordinate"];
}

#pragma mark -
#pragma mark Managing targets

- (GLuint)textureForOutput;
{
    return secondFilterOutputTexture;
}

#pragma mark -
#pragma mark Manage the output texture

- (void)initializeSecondOutputTextureIfNeeded;
{
    if ([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage)
    {
        return;
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext useImageProcessingContext];
        
        if (!secondFilterOutputTexture)
        {
            glGenTextures(1, &secondFilterOutputTexture);
            glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    });
}

- (void)deleteOutputTexture;
{
    if (outputTexture)
    {
        glDeleteTextures(1, &outputTexture);
        outputTexture = 0;
    }

    if (!([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage))
    {
        if (secondFilterOutputTexture)
        {
            glDeleteTextures(1, &secondFilterOutputTexture);
            secondFilterOutputTexture = 0;
        }
    }
}

#pragma mark -
#pragma mark Managing the display FBOs

- (void)createFilterFBOofSize:(CGSize)currentFBOSize;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext useImageProcessingContext];

        if (!filterFramebuffer)
        {
            if ([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage)
            {
                preparedToCaptureImage = NO;
                [super createFilterFBOofSize:currentFBOSize];
                preparedToCaptureImage = YES;
            }
            else
            {
                [super createFilterFBOofSize:currentFBOSize];
            }
        }
        
        glGenFramebuffers(1, &secondFilterFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, secondFilterFramebuffer);

        if ([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage)
        {
    #if defined(__IPHONE_6_0)
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &filterTextureCache);
    #else
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &filterTextureCache);
    #endif

            if (err) 
            {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
            }
            
            // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
            
            CFDictionaryRef empty; // empty value for attr value.
            CFMutableDictionaryRef attrs;
            empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
            attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
            
            err = CVPixelBufferCreate(kCFAllocatorDefault, (int)currentFBOSize.width, (int)currentFBOSize.height, kCVPixelFormatType_32BGRA, attrs, &renderTarget);
            if (err) 
            {
                NSLog(@"FBO size: %f, %f", currentFBOSize.width, currentFBOSize.height);
                NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
            }
            
            err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault,
                                                                filterTextureCache, renderTarget,
                                                                NULL, // texture attributes
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA, // opengl format
                                                                (int)currentFBOSize.width, 
                                                                (int)currentFBOSize.height,
                                                                GL_BGRA, // native iOS format
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &renderTexture);
            if (err) 
            {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            CFRelease(attrs);
            CFRelease(empty);
            glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
            secondFilterOutputTexture = CVOpenGLESTextureGetName(renderTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
            
            [self notifyTargetsAboutNewOutputTexture];
        }
        else
        {
            [self initializeSecondOutputTextureIfNeeded];
            glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
//            if ([self providesMonochromeOutput] && [GPUImageOpenGLESContext deviceSupportsRedTextures])
//            {
//                glTexImage2D(GL_TEXTURE_2D, 0, GL_RG_EXT, (int)currentFBOSize.width, (int)currentFBOSize.height, 0, GL_RG_EXT, GL_UNSIGNED_BYTE, 0);
//            }
//            else
//            {
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)currentFBOSize.width, (int)currentFBOSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
//            }
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, secondFilterOutputTexture, 0);
            
            [self notifyTargetsAboutNewOutputTexture];
        }
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
        
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)recreateFilterFBO
{
    cachedMaximumOutputSize = CGSizeZero;
    
    [self destroyFilterFBO];
    [self deleteOutputTexture];
//    
//    [self setFilterFBO];
//    [self setSecondFilterFBO];
}

- (void)destroyFilterFBO;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext useImageProcessingContext];
        
        if (filterFramebuffer)
        {
            glDeleteFramebuffers(1, &filterFramebuffer);
            filterFramebuffer = 0;
        }

        if (secondFilterFramebuffer)
        {
            glDeleteFramebuffers(1, &secondFilterFramebuffer);
            secondFilterFramebuffer = 0;
        }	
        
        if (filterTextureCache != NULL)
        {
            CFRelease(renderTarget);
            renderTarget = NULL;
            
            if (renderTexture)
            {
                CFRelease(renderTexture);
                renderTexture = NULL;
            }
            
            CVOpenGLESTextureCacheFlush(filterTextureCache, 0);
            CFRelease(filterTextureCache);
            filterTextureCache = NULL;
        }
    });
}

- (void)setFilterFBO;
{
    CGSize currentFBOSize = [self sizeOfFBO];

    if (!filterFramebuffer)
    {
        if ([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage)
        {
            preparedToCaptureImage = NO;
            [super createFilterFBOofSize:currentFBOSize];
            preparedToCaptureImage = YES;
        }
        else
        {
            [super createFilterFBOofSize:currentFBOSize];
        }
        [self setupFilterForSize:currentFBOSize];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, filterFramebuffer);
    
    glViewport(0, 0, (int)currentFBOSize.width, (int)currentFBOSize.height);
}

- (void)setSecondFilterFBO;
{
    if (!secondFilterFramebuffer)
    {
        CGSize currentFBOSize = [self sizeOfFBO];
        [self createFilterFBOofSize:currentFBOSize];
        [self setupFilterForSize:currentFBOSize];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, secondFilterFramebuffer);
    CGSize currentFBOSize = [self sizeOfFBO];
    glViewport(0, 0, (int)currentFBOSize.width, (int)currentFBOSize.height);
}

- (void)setOutputFBO;
{
    [self setSecondFilterFBO];
}

#pragma mark -
#pragma mark Rendering

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    if (self.preventRendering)
    {
        return;
    }
    
    // This assumes that any two-pass filter that says it desires monochrome input is using the first pass for a luminance conversion, which can be dropped
    if (!currentlyReceivingMonochromeInput)
    {
        // Run the first stage of the two-pass filter
        [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates sourceTexture:sourceTexture];
    }
    
    // Run the second stage of the two-pass filter
    [self setSecondFilterFBO];
    
    [GPUImageOpenGLESContext setActiveShaderProgram:secondFilterProgram];
    [self setUniformsForProgramAtIndex:1];

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (!currentlyReceivingMonochromeInput)
    {
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, outputTexture);
        glVertexAttribPointer(secondFilterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [[self class] textureCoordinatesForRotation:kGPUImageNoRotation]);
    }
    else
    {
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, sourceTexture);
        glVertexAttribPointer(secondFilterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    }
    
	glUniform1i(secondFilterInputTextureUniform, 3);
    
    glVertexAttribPointer(secondFilterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    // Release the first FBO early
    if (shouldConserveMemoryForNextFrame)
    {
        [firstTextureDelegate textureNoLongerNeededForTarget:self];

        glDeleteFramebuffers(1, &filterFramebuffer);
        filterFramebuffer = 0;
        
        if (outputTexture)
        {
            glDeleteTextures(1, &outputTexture);
            outputTexture = 0;
        }
        
        shouldConserveMemoryForNextFrame = NO;
    }
}

// Clear this out because I want to release the input texture as soon as the first pass is finished, not just after the whole rendering has completed
- (void)releaseInputTexturesIfNeeded;
{
}

- (void)prepareForImageCapture;
{
    if (preparedToCaptureImage)
    {
        return;
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        preparedToCaptureImage = YES;
        
        if ([GPUImageOpenGLESContext supportsFastTextureUpload])
        {
            if (secondFilterOutputTexture)
            {
                [GPUImageOpenGLESContext useImageProcessingContext];

                glDeleteTextures(1, &secondFilterOutputTexture);
                secondFilterOutputTexture = 0;
            }
        }
    });
}

- (void)setAndExecuteUniformStateCallbackAtIndex:(GLint)uniform forProgram:(GLProgram *)shaderProgram toBlock:(dispatch_block_t)uniformStateBlock;
{
// TODO: Deal with the fact that two-pass filters may have the same shader program identifier
    if (shaderProgram == filterProgram)
    {
        [uniformStateRestorationBlocks setObject:[uniformStateBlock copy] forKey:[NSNumber numberWithInt:uniform]];
    }
    else
    {
        [secondProgramUniformStateRestorationBlocks setObject:[uniformStateBlock copy] forKey:[NSNumber numberWithInt:uniform]];
    }
    uniformStateBlock();
}

- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;
{
    if (programIndex == 0)
    {
        [uniformStateRestorationBlocks enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            dispatch_block_t currentBlock = obj;
            currentBlock();
        }];
    }
    else
    {
        [secondProgramUniformStateRestorationBlocks enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            dispatch_block_t currentBlock = obj;
            currentBlock();
        }];
    }
}

@end

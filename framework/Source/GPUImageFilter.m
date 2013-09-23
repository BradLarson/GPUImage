#import "GPUImageFilter.h"
#import "GPUImagePicture.h"
#import <AVFoundation/AVFoundation.h>

// Hardcode the vertex shader for standard filters, but this can be overridden
NSString *const kGPUImageVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE

NSString *const kGPUImagePassthroughFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);

#else

NSString *const kGPUImagePassthroughFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);
#endif


void dataProviderReleaseCallback (void *info, const void *data, size_t size);
void dataProviderUnlockCallback (void *info, const void *data, size_t size);

@implementation GPUImageFilter

@synthesize renderTarget;
@synthesize preventRendering = _preventRendering;
@synthesize currentlyReceivingMonochromeInput;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    uniformStateRestorationBlocks = [NSMutableDictionary dictionaryWithCapacity:10];
    preparedToCaptureImage = NO;
    _preventRendering = NO;
    currentlyReceivingMonochromeInput = NO;
    inputRotation = kGPUImageNoRotation;
    backgroundColorRed = 0.0;
    backgroundColorGreen = 0.0;
    backgroundColorBlue = 0.0;
    backgroundColorAlpha = 0.0;
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];

        filterProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        
        if (!filterProgram.initialized)
        {
            [self initializeAttributes];
            
            if (![filterProgram link])
            {
                NSString *progLog = [filterProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [filterProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [filterProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                filterProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        
        filterPositionAttribute = [filterProgram attributeIndex:@"position"];
        filterTextureCoordinateAttribute = [filterProgram attributeIndex:@"inputTextureCoordinate"];
        filterInputTextureUniform = [filterProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
        
        [GPUImageContext setActiveShaderProgram:filterProgram];
        
        glEnableVertexAttribArray(filterPositionAttribute);
        glEnableVertexAttribArray(filterTextureCoordinateAttribute);    
    });
    
    return self;
}

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [self initWithVertexShaderFromString:kGPUImageVertexShaderString fragmentShaderFromString:fragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

- (id)initWithFragmentShaderFromFile:(NSString *)fragmentShaderFilename;
{
    NSString *fragmentShaderPathname = [[NSBundle mainBundle] pathForResource:fragmentShaderFilename ofType:@"fsh"];
    NSString *fragmentShaderString = [NSString stringWithContentsOfFile:fragmentShaderPathname encoding:NSUTF8StringEncoding error:nil];

    if (!(self = [self initWithFragmentShaderFromString:fragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kGPUImagePassthroughFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

- (void)initializeAttributes;
{
    [filterProgram addAttribute:@"position"];
	[filterProgram addAttribute:@"inputTextureCoordinate"];

    // Override this, calling back to this super method, in order to add new attributes to your vertex shader
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    // This is where you can override to provide some custom setup, if your filter has a size-dependent element
}

- (void)dealloc
{
    [self destroyFilterFBO];
}

#pragma mark -
#pragma mark Still image processing

void dataProviderReleaseCallback (void *info, const void *data, size_t size)
{
    free((void *)data);
}

void dataProviderUnlockCallback (void *info, const void *data, size_t size)
{
    GPUImageFilter *filter = (__bridge_transfer GPUImageFilter*)info;
    
    CVPixelBufferUnlockBaseAddress([filter renderTarget], 0);
    if ([filter renderTarget]) {
        CFRelease([filter renderTarget]);
    }

    [filter destroyFilterFBO];

    filter.preventRendering = NO;
}

- (CGImageRef)newCGImageFromCurrentlyProcessedOutputWithOrientation:(UIImageOrientation)imageOrientation
{
    
    // a CGImage can only be created from a 'normal' color texture
    NSAssert(self.outputTextureOptions.internalFormat == GL_RGBA, @"For conversion to a CGImage the output texture format for this filter must be GL_RGBA.");
    NSAssert(self.outputTextureOptions.type == GL_UNSIGNED_BYTE, @"For conversion to a CGImage the type of the output texture of this filter must be GL_UNSIGNED_BYTE.");
    
    __block CGImageRef cgImageFromBytes;

    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        CGSize currentFBOSize = [self sizeOfFBO];
        NSUInteger totalBytesForImage = (int)currentFBOSize.width * (int)currentFBOSize.height * 4;
        // It appears that the width of a texture must be padded out to be a multiple of 8 (32 bytes) if reading from it using a texture cache
        NSUInteger paddedWidthOfImage = CVPixelBufferGetBytesPerRow(renderTarget) / 4.0;
        NSUInteger paddedBytesForImage = paddedWidthOfImage * (int)currentFBOSize.height * 4;
        
        GLubyte *rawImagePixels;
        
        CGDataProviderRef dataProvider;
        if ([GPUImageContext supportsFastTextureUpload] && preparedToCaptureImage)
        {
            //        glFlush();
            glFinish();
            CFRetain(renderTarget); // I need to retain the pixel buffer here and release in the data source callback to prevent its bytes from being prematurely deallocated during a photo write operation
            CVPixelBufferLockBaseAddress(renderTarget, 0);
            self.preventRendering = YES; // Locks don't seem to work, so prevent any rendering to the filter which might overwrite the pixel buffer data until done processing
            rawImagePixels = (GLubyte *)CVPixelBufferGetBaseAddress(renderTarget);
            dataProvider = CGDataProviderCreateWithData((__bridge_retained void*)self, rawImagePixels, paddedBytesForImage, dataProviderUnlockCallback);
        }
        else
        {
            [self setOutputFBO];
            rawImagePixels = (GLubyte *)malloc(totalBytesForImage);
            glReadPixels(0, 0, (int)currentFBOSize.width, (int)currentFBOSize.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);
            dataProvider = CGDataProviderCreateWithData(NULL, rawImagePixels, totalBytesForImage, dataProviderReleaseCallback);
        }
        
        
        CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
        
        if ([GPUImageContext supportsFastTextureUpload] && preparedToCaptureImage)
        {
            cgImageFromBytes = CGImageCreate((int)currentFBOSize.width, (int)currentFBOSize.height, 8, 32, CVPixelBufferGetBytesPerRow(renderTarget), defaultRGBColorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, dataProvider, NULL, NO, kCGRenderingIntentDefault);
        }
        else
        {
            cgImageFromBytes = CGImageCreate((int)currentFBOSize.width, (int)currentFBOSize.height, 8, 32, 4 * (int)currentFBOSize.width, defaultRGBColorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaLast, dataProvider, NULL, NO, kCGRenderingIntentDefault);
        }
        
        // Capture image with current device orientation
        CGDataProviderRelease(dataProvider);
        CGColorSpaceRelease(defaultRGBColorSpace);
    });

    return cgImageFromBytes;
}

- (CGImageRef)newCGImageByFilteringCGImage:(CGImageRef)imageToFilter
{
    return [self newCGImageByFilteringCGImage:imageToFilter orientation:UIImageOrientationUp];
}

- (CGImageRef)newCGImageByFilteringCGImage:(CGImageRef)imageToFilter orientation:(UIImageOrientation)orientation;
{
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithCGImage:imageToFilter];
    
    [stillImageSource addTarget:self];
    [stillImageSource processImage];
    
    CGImageRef processedImage = [self newCGImageFromCurrentlyProcessedOutputWithOrientation:orientation];
    
    [stillImageSource removeTarget:self];
    return processedImage;
}

#pragma mark -
#pragma mark Managing the display FBOs

- (CGSize)sizeOfFBO;
{
    CGSize outputSize = [self maximumOutputSize];
    if ( (CGSizeEqualToSize(outputSize, CGSizeZero)) || (inputTextureSize.width < outputSize.width) )
    {
        return inputTextureSize;
    }
    else
    {
        return outputSize;
    }
}

- (void)createFilterFBOofSize:(CGSize)currentFBOSize;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        glActiveTexture(GL_TEXTURE1);
        
        glGenFramebuffers(1, &filterFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, filterFramebuffer);
        
        if ([GPUImageContext supportsFastTextureUpload] && preparedToCaptureImage)
        {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#if defined(__IPHONE_6_0)
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[GPUImageContext sharedImageProcessingContext] context], NULL, &filterTextureCache);
#else
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageContext sharedImageProcessingContext] context], NULL, &filterTextureCache);
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
                                                                self.outputTextureOptions.internalFormat, // opengl format
                                                                (int)currentFBOSize.width,
                                                                (int)currentFBOSize.height,
                                                                self.outputTextureOptions.format, // native iOS format
                                                                self.outputTextureOptions.type,
                                                                0,
                                                                &renderTexture);
            if (err)
            {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            CFRelease(attrs);
            CFRelease(empty);

            glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
            outputTexture = CVOpenGLESTextureGetName(renderTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self.outputTextureOptions.wrapS);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self.outputTextureOptions.wrapT);
            
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
            
            [self notifyTargetsAboutNewOutputTexture];
#endif
        }
        else
        {
            [self initializeOutputTextureIfNeeded];
            
            glBindTexture(GL_TEXTURE_2D, outputTexture);
            
//            if ([self providesMonochromeOutput] && [GPUImageContext deviceSupportsRedTextures])
//            {
//                glTexImage2D(GL_TEXTURE_2D, 0, GL_RG_EXT, (int)currentFBOSize.width, (int)currentFBOSize.height, 0, GL_RG_EXT, GL_UNSIGNED_BYTE, 0);
//            }
//            else
//            {
                glTexImage2D(GL_TEXTURE_2D,
                             0,
                             self.outputTextureOptions.internalFormat,
                             (int)currentFBOSize.width,
                             (int)currentFBOSize.height,
                             0,
                             self.outputTextureOptions.format,
                             self.outputTextureOptions.type,
                             0);
//            }
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outputTexture, 0);
//            glBindFramebuffer(GL_FRAMEBUFFER, filterFramebuffer);
//            GLenum att = GL_COLOR_ATTACHMENT0;
//            glDrawBuffers(1, &att);
            [self notifyTargetsAboutNewOutputTexture];
        }
        
        //    NSLog(@"Filter size: %f, %f for filter: %@", currentFBOSize.width, currentFBOSize.height, self);
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)destroyFilterFBO;
{
    if (filterFramebuffer)
	{
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageContext useImageProcessingContext];

            glDeleteFramebuffers(1, &filterFramebuffer);
            filterFramebuffer = 0;

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
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
#endif
        });
	}
}

- (void)setFilterFBO;
{
    if (!filterFramebuffer)
    {
        CGSize currentFBOSize = [self sizeOfFBO];
        [self createFilterFBOofSize:currentFBOSize];
        [self setupFilterForSize:currentFBOSize];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, filterFramebuffer);
    
    CGSize currentFBOSize = [self sizeOfFBO];
    glViewport(0, 0, (int)currentFBOSize.width, (int)currentFBOSize.height);
}

- (void)setOutputFBO;
{
    // Override this for filters that have multiple framebuffers
    [self setFilterFBO];
}

- (void)releaseInputTexturesIfNeeded;
{
    if (shouldConserveMemoryForNextFrame)
    {
        [firstTextureDelegate textureNoLongerNeededForTarget:self];
        shouldConserveMemoryForNextFrame = NO;
    }
}

#pragma mark -
#pragma mark Rendering

+ (const GLfloat *)textureCoordinatesForRotation:(GPUImageRotationMode)rotationMode;
{
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };

    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };

    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };

    switch(rotationMode)
    {
        case kGPUImageNoRotation: return noRotationTextureCoordinates;
        case kGPUImageRotateLeft: return rotateLeftTextureCoordinates;
        case kGPUImageRotateRight: return rotateRightTextureCoordinates;
        case kGPUImageFlipVertical: return verticalFlipTextureCoordinates;
        case kGPUImageFlipHorizonal: return horizontalFlipTextureCoordinates;
        case kGPUImageRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case kGPUImageRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case kGPUImageRotate180: return rotate180TextureCoordinates;
    }
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    if (self.preventRendering)
    {
        return;
    }
    
    [GPUImageContext setActiveShaderProgram:filterProgram];
    [self setFilterFBO];
    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);

	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, sourceTexture);
	
	glUniform1i(filterInputTextureUniform, 2);	

    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
	glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
{
    if (self.frameProcessingCompletionBlock != NULL)
    {
        self.frameProcessingCompletionBlock(self, frameTime);
    }
    
    [self releaseInputTexturesIfNeeded];
    
    for (id<GPUImageInput> currentTarget in targets)
    {
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            if ([GPUImageContext supportsFastTextureUpload] && preparedToCaptureImage)
            {
                [self setInputTextureForTarget:currentTarget atIndex:textureIndex];
            }
            
            [currentTarget setInputSize:[self outputFrameSize] atIndex:textureIndex];
            [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (CGSize)outputFrameSize;
{
    return inputTextureSize;
}

- (void)prepareForImageCapture;
{
    if (preparedToCaptureImage)
    {
        return;
    }

    preparedToCaptureImage = YES;
    
    if ([GPUImageContext supportsFastTextureUpload])
    {
        if (outputTexture)
        {
            runSynchronouslyOnVideoProcessingQueue(^{
                [GPUImageContext useImageProcessingContext];
                
                glDeleteTextures(1, &outputTexture);
                outputTexture = 0;
            });
        }
    }
}

#pragma mark -
#pragma mark Input parameters

- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
{
    backgroundColorRed = redComponent;
    backgroundColorGreen = greenComponent;
    backgroundColorBlue = blueComponent;
    backgroundColorAlpha = alphaComponent;
}

- (void)setInteger:(GLint)newInteger forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setInteger:newInteger forUniform:uniformIndex program:filterProgram];
}

- (void)setFloat:(GLfloat)newFloat forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setFloat:newFloat forUniform:uniformIndex program:filterProgram];
}

- (void)setSize:(CGSize)newSize forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setSize:newSize forUniform:uniformIndex program:filterProgram];
}

- (void)setPoint:(CGPoint)newPoint forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setPoint:newPoint forUniform:uniformIndex program:filterProgram];
}

- (void)setFloatVec3:(GPUVector3)newVec3 forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setVec3:newVec3 forUniform:uniformIndex program:filterProgram];
}

- (void)setFloatVec4:(GPUVector4)newVec4 forUniform:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setVec4:newVec4 forUniform:uniformIndex program:filterProgram];
}

- (void)setFloatArray:(GLfloat *)array length:(GLsizei)count forUniform:(NSString*)uniformName
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    
    [self setFloatArray:array length:count forUniform:uniformIndex program:filterProgram];
}

- (void)setMatrix3f:(GPUMatrix3x3)matrix forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniformMatrix3fv(uniform, 1, GL_FALSE, (GLfloat *)&matrix);
        }];
    });
}

- (void)setMatrix4f:(GPUMatrix4x4)matrix forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniformMatrix4fv(uniform, 1, GL_FALSE, (GLfloat *)&matrix);
        }];
    });
}

- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1f(uniform, floatValue);
        }];
    });
}

- (void)setPoint:(CGPoint)pointValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            GLfloat positionArray[2];
            positionArray[0] = pointValue.x;
            positionArray[1] = pointValue.y;
            
            glUniform2fv(uniform, 1, positionArray);
        }];
    });
}

- (void)setSize:(CGSize)sizeValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:shaderProgram];
        
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            GLfloat sizeArray[2];
            sizeArray[0] = sizeValue.width;
            sizeArray[1] = sizeValue.height;
            
            glUniform2fv(uniform, 1, sizeArray);
        }];
    });
}

- (void)setVec3:(GPUVector3)vectorValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:shaderProgram];

        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform3fv(uniform, 1, (GLfloat *)&vectorValue);
        }];
    });
}

- (void)setVec4:(GPUVector4)vectorValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:shaderProgram];
        
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform4fv(uniform, 1, (GLfloat *)&vectorValue);
        }];
    });
}

- (void)setFloatArray:(GLfloat *)arrayValue length:(GLsizei)arrayLength forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:shaderProgram];
        
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1fv(uniform, arrayLength, arrayValue);
        }];
    });
}

- (void)setInteger:(GLint)intValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:shaderProgram];

        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1i(uniform, intValue);
        }];
    });
}

- (void)setAndExecuteUniformStateCallbackAtIndex:(GLint)uniform forProgram:(GLProgram *)shaderProgram toBlock:(dispatch_block_t)uniformStateBlock;
{
    [uniformStateRestorationBlocks setObject:[uniformStateBlock copy] forKey:[NSNumber numberWithInt:uniform]];
    uniformStateBlock();
}

- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;
{
    [uniformStateRestorationBlocks enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        dispatch_block_t currentBlock = obj;
        currentBlock();
    }];
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
    
    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation] sourceTexture:filterSourceTexture];

    [self informTargetsAboutNewFrameAtTime:frameTime];
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputTexture:(GLuint)newInputTexture atIndex:(NSInteger)textureIndex;
{
    filterSourceTexture = newInputTexture;
}

- (void)recreateFilterFBO
{
    cachedMaximumOutputSize = CGSizeZero;
    if (!filterFramebuffer)
    {
        return;
    }
    
    [self destroyFilterFBO];
    [self deleteOutputTexture];
    
    [self setFilterFBO];
}

- (CGSize)rotatedSize:(CGSize)sizeToRotate forIndex:(NSInteger)textureIndex;
{
    CGSize rotatedSize = sizeToRotate;
    
    if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
    {
        rotatedSize.width = sizeToRotate.height;
        rotatedSize.height = sizeToRotate.width;
    }
    
    return rotatedSize; 
}

- (CGPoint)rotatedPoint:(CGPoint)pointToRotate forRotation:(GPUImageRotationMode)rotation;
{
    CGPoint rotatedPoint;
    switch(rotation)
    {
        case kGPUImageNoRotation: return pointToRotate; break;
        case kGPUImageFlipHorizonal:
        {
            rotatedPoint.x = 1.0 - pointToRotate.x;
            rotatedPoint.y = pointToRotate.y;
        }; break;
        case kGPUImageFlipVertical:
        {
            rotatedPoint.x = pointToRotate.x;
            rotatedPoint.y = 1.0 - pointToRotate.y;
        }; break;
        case kGPUImageRotateLeft:
        {
            rotatedPoint.x = 1.0 - pointToRotate.y;
            rotatedPoint.y = pointToRotate.x;
        }; break;
        case kGPUImageRotateRight:
        {
            rotatedPoint.x = pointToRotate.y;
            rotatedPoint.y = 1.0 - pointToRotate.x;
        }; break;
        case kGPUImageRotateRightFlipVertical:
        {
            rotatedPoint.x = pointToRotate.y;
            rotatedPoint.y = pointToRotate.x;
        }; break;
        case kGPUImageRotateRightFlipHorizontal:
        {
            rotatedPoint.x = 1.0 - pointToRotate.y;
            rotatedPoint.y = 1.0 - pointToRotate.x;
        }; break;
        case kGPUImageRotate180:
        {
            rotatedPoint.x = 1.0 - pointToRotate.x;
            rotatedPoint.y = 1.0 - pointToRotate.y;
        }; break;
    }
    
    return rotatedPoint;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    if (self.preventRendering)
    {
        return;
    }
    
    if (overrideInputSize)
    {
        if (CGSizeEqualToSize(forcedMaximumSize, CGSizeZero))
        {
            return;
        }
        else
        {
            CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(newSize, CGRectMake(0.0, 0.0, forcedMaximumSize.width, forcedMaximumSize.height));
            inputTextureSize = insetRect.size;
            return;
        }
    }
    
    CGSize rotatedSize = [self rotatedSize:newSize forIndex:textureIndex];
    
    if (CGSizeEqualToSize(rotatedSize, CGSizeZero))
    {
        inputTextureSize = rotatedSize;
    }
    else if (!CGSizeEqualToSize(inputTextureSize, rotatedSize))
    {
        inputTextureSize = rotatedSize;
        [self recreateFilterFBO];
    }
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    inputRotation = newInputRotation;
}

- (void)forceProcessingAtSize:(CGSize)frameSize;
{    
    if (CGSizeEqualToSize(frameSize, CGSizeZero))
    {
        overrideInputSize = NO;
    }
    else
    {
        overrideInputSize = YES;
        inputTextureSize = frameSize;
        forcedMaximumSize = CGSizeZero;
    }
    
    [self destroyFilterFBO];
    
    for (id<GPUImageInput> currentTarget in targets)
    {
        if ([currentTarget respondsToSelector:@selector(destroyFilterFBO)]) {
            [currentTarget performSelector:@selector(destroyFilterFBO)];
        }
    }
}

- (void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize;
{
    if (CGSizeEqualToSize(frameSize, CGSizeZero))
    {
        overrideInputSize = NO;
        inputTextureSize = CGSizeZero;
        forcedMaximumSize = CGSizeZero;
    }
    else
    {
        overrideInputSize = YES;
        forcedMaximumSize = frameSize;
    }
    
    [self destroyFilterFBO];
    
    for (id<GPUImageInput> currentTarget in targets)
    {
        if ([currentTarget respondsToSelector:@selector(destroyFilterFBO)]) {
            [currentTarget performSelector:@selector(destroyFilterFBO)];
        }
    }
}

- (void)cleanupOutputImage;
{
//    NSLog(@"Cleaning up output filter image: %@", self);
    [self destroyFilterFBO];
    [self deleteOutputTexture];
}

- (void)deleteOutputTexture;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];

        if (!([GPUImageContext supportsFastTextureUpload] && preparedToCaptureImage))
        {
            if (outputTexture)
            {
                glDeleteTextures(1, &outputTexture);
                outputTexture = 0;
            }
        }
    });
}

- (CGSize)maximumOutputSize;
{
    // I'm temporarily disabling adjustments for smaller output sizes until I figure out how to make this work better
    return CGSizeZero;

    /*
    if (CGSizeEqualToSize(cachedMaximumOutputSize, CGSizeZero))
    {
        for (id<GPUImageInput> currentTarget in targets)
        {
            if ([currentTarget maximumOutputSize].width > cachedMaximumOutputSize.width)
            {
                cachedMaximumOutputSize = [currentTarget maximumOutputSize];
            }
        }
    }
    
    return cachedMaximumOutputSize;
     */
}

- (void)endProcessing 
{
    for (id<GPUImageInput> currentTarget in targets)
    {
        [currentTarget endProcessing];
    }
}

- (void)setTextureDelegate:(id<GPUImageTextureDelegate>)newTextureDelegate atIndex:(NSInteger)textureIndex;
{
    firstTextureDelegate = newTextureDelegate;
}

- (void)conserveMemoryForNextFrame;
{
    if (overrideInputSize)
    {
        return;
    }
    
    shouldConserveMemoryForNextFrame = YES;

    for (id<GPUImageInput> currentTarget in targets)
    {
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            [currentTarget conserveMemoryForNextFrame];
        }
    }
}

- (BOOL)wantsMonochromeInput;
{
    return NO;
}

#pragma mark -
#pragma mark Accessors

@end

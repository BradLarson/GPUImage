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

NSString *const kGPUImagePassthroughFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);

void dataProviderReleaseCallback (void *info, const void *data, size_t size);
void dataProviderUnlockCallback (void *info, const void *data, size_t size);

@implementation GPUImageFilter

@synthesize renderTarget;
@synthesize preventRendering = _preventRendering;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    preparedToCaptureImage = NO;
    _preventRendering = NO;
    inputRotation = kGPUImageNoRotation;
    backgroundColorRed = 0.0;
    backgroundColorGreen = 0.0;
    backgroundColorBlue = 0.0;
    backgroundColorAlpha = 0.0;
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext useImageProcessingContext];

        filterProgram = [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] programForVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        
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
        
        [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
        
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
    CFRelease([filter renderTarget]);

    [filter destroyFilterFBO];

    filter.preventRendering = NO;
}

- (CGImageRef)newCGImageFromCurrentlyProcessedOutputWithOrientation:(UIImageOrientation)imageOrientation
{
    __block CGImageRef cgImageFromBytes;

    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext useImageProcessingContext];
        
        CGSize currentFBOSize = [self sizeOfFBO];
        NSUInteger totalBytesForImage = (int)currentFBOSize.width * (int)currentFBOSize.height * 4;
        // It appears that the width of a texture must be padded out to be a multiple of 8 (32 bytes) if reading from it using a texture cache
        NSUInteger paddedWidthOfImage = CVPixelBufferGetBytesPerRow(renderTarget) / 4.0;
        NSUInteger paddedBytesForImage = paddedWidthOfImage * (int)currentFBOSize.height * 4;
        
        GLubyte *rawImagePixels;
        
        CGDataProviderRef dataProvider;
        if ([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage)
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
        
        if ([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage)
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

- (UIImage *)imageFromCurrentlyProcessedOutputWithOrientation:(UIImageOrientation)imageOrientation;
{
    CGImageRef cgImageFromBytes = [self newCGImageFromCurrentlyProcessedOutputWithOrientation:imageOrientation];
    UIImage *finalImage = [UIImage imageWithCGImage:cgImageFromBytes scale:1.0 orientation:imageOrientation];
    CGImageRelease(cgImageFromBytes);

    return finalImage;
}

- (CGImageRef)newCGImageByFilteringCGImage:(CGImageRef)imageToFilter
{
    return [self newCGImageByFilteringCGImage:imageToFilter orientation:UIImageOrientationUp];
}

- (CGImageRef)newCGImageByFilteringCGImage:(CGImageRef)imageToFilter orientation:(UIImageOrientation)orientation;
{
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithCGImage:imageToFilter];
    
    [self prepareForImageCapture];
    
    [stillImageSource addTarget:self];
    [stillImageSource processImage];
    
    CGImageRef processedImage = [self newCGImageFromCurrentlyProcessedOutputWithOrientation:orientation];
    
    [stillImageSource removeTarget:self];
    return processedImage;
}

- (CGImageRef)newCGImageByFilteringImage:(UIImage *)imageToFilter
{
    return [self newCGImageByFilteringCGImage:[imageToFilter CGImage] orientation:[imageToFilter imageOrientation]];
}

- (UIImage *)imageByFilteringImage:(UIImage *)imageToFilter;
{
    CGImageRef image = [self newCGImageByFilteringCGImage:[imageToFilter CGImage] orientation:[imageToFilter imageOrientation]];
    UIImage *processedImage = [UIImage imageWithCGImage:image scale:[imageToFilter scale] orientation:[imageToFilter imageOrientation]];
    CGImageRelease(image);
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
        [GPUImageOpenGLESContext useImageProcessingContext];
        glActiveTexture(GL_TEXTURE1);
        
        glGenFramebuffers(1, &filterFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, filterFramebuffer);
        
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
            outputTexture = CVOpenGLESTextureGetName(renderTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
            
            [self notifyTargetsAboutNewOutputTexture];
        }
        else
        {
            [self initializeOutputTextureIfNeeded];
            
            glBindTexture(GL_TEXTURE_2D, outputTexture);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)currentFBOSize.width, (int)currentFBOSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outputTexture, 0);
            
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
            [GPUImageOpenGLESContext useImageProcessingContext];

            glDeleteFramebuffers(1, &filterFramebuffer);
            filterFramebuffer = 0;
            
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
        case kGPUImageRotate180: return rotate180TextureCoordinates;
    }
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    if (self.preventRendering)
    {
        return;
    }
    
    [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
    [self setUniformsForProgramAtIndex:0];
    [self setFilterFBO];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);

	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, sourceTexture);
	
	glUniform1i(filterInputTextureUniform, 2);	

    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
	glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;
{
    
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
            
            if ([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage)
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
    
    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        if (outputTexture)
        {
            runSynchronouslyOnVideoProcessingQueue(^{
                [GPUImageOpenGLESContext useImageProcessingContext];
                
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
        [GPUImageOpenGLESContext setActiveShaderProgram:shaderProgram];
        glUniformMatrix3fv(uniform, 1, GL_FALSE, (GLfloat *)&matrix);
    });
}

- (void)setMatrix4f:(GPUMatrix4x4)matrix forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext setActiveShaderProgram:shaderProgram];
        glUniformMatrix4fv(uniform, 1, GL_FALSE, (GLfloat *)&matrix);
    });
}

- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext setActiveShaderProgram:shaderProgram];
        glUniform1f(uniform, floatValue);
    });
}

- (void)setPoint:(CGPoint)pointValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext setActiveShaderProgram:shaderProgram];

        GLfloat positionArray[2];
        positionArray[0] = pointValue.x;
        positionArray[1] = pointValue.y;
        
        glUniform2fv(uniform, 1, positionArray);
    });
}

- (void)setSize:(CGSize)sizeValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext setActiveShaderProgram:shaderProgram];
        
        GLfloat sizeArray[2];
        sizeArray[0] = sizeValue.width;
        sizeArray[1] = sizeValue.height;
        
        glUniform2fv(uniform, 1, sizeArray);
    });
}

- (void)setVec3:(GPUVector3)vectorValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext setActiveShaderProgram:shaderProgram];

        glUniform3fv(uniform, 1, (GLfloat *)&vectorValue);
    });
}

- (void)setVec4:(GPUVector4)vectorValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext setActiveShaderProgram:shaderProgram];
        
        glUniform4fv(uniform, 1, (GLfloat *)&vectorValue);
    });
}

- (void)setFloatArray:(GLfloat *)arrayValue length:(GLsizei)arrayLength forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext setActiveShaderProgram:shaderProgram];
        
        glUniform1fv(uniform, arrayLength, arrayValue);
    });
}

- (void)setInteger:(GLint)intValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext setActiveShaderProgram:shaderProgram];
        glUniform1i(uniform, intValue);
    });
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
    if (!([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage))
    {
        if (outputTexture)
        {
            glDeleteTextures(1, &outputTexture);
            outputTexture = 0;
        }
    }
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

#pragma mark -
#pragma mark Accessors

@end

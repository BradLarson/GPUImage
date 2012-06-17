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
    
    secondFilterProgram = [[GLProgram alloc] initWithVertexShaderString:secondStageVertexShaderString fragmentShaderString:secondStageFragmentShaderString];
    
    [self initializeAttributes];
    
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
    
    secondFilterPositionAttribute = [secondFilterProgram attributeIndex:@"position"];
    secondFilterTextureCoordinateAttribute = [secondFilterProgram attributeIndex:@"inputTextureCoordinate"];
    secondFilterInputTextureUniform = [secondFilterProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
    secondFilterInputTextureUniform2 = [secondFilterProgram uniformIndex:@"inputImageTexture2"]; // This does assume a name of "inputImageTexture2" for second input texture in the fragment shader
    
    [secondFilterProgram use];    
	glEnableVertexAttribArray(secondFilterPositionAttribute);
	glEnableVertexAttribArray(secondFilterTextureCoordinateAttribute);

    return self;
}

- (id)initWithFirstStageFragmentShaderFromString:(NSString *)firstStageFragmentShaderString secondStageFragmentShaderFromString:(NSString *)secondStageFragmentShaderString;
{
    if (!(self = [self initWithFirstStageVertexShaderFromString:kGPUImageVertexShaderString firstStageFragmentShaderFromString:firstStageFragmentShaderString secondStageVertexShaderFromString:kGPUImageVertexShaderString secondStageFragmentShaderFromString:firstStageFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

- (void)initializeAttributes;
{
    [super initializeAttributes];
    [secondFilterProgram addAttribute:@"position"];
	[secondFilterProgram addAttribute:@"inputTextureCoordinate"];
}

#pragma mark -
#pragma mark Managing targets

- (void)setInputTextureForTarget:(id<GPUImageInput>)target atIndex:(NSInteger)inputTextureIndex;
{
    [target setInputTexture:secondFilterOutputTexture atIndex:inputTextureIndex];
}

#pragma mark -
#pragma mark Manage the output texture

- (void)initializeOutputTexture;
{
    [super initializeOutputTexture];
    
    glGenTextures(1, &secondFilterOutputTexture);
	glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)deleteOutputTexture;
{
    [super deleteOutputTexture];
    
    if (secondFilterOutputTexture)
    {
        glDeleteTextures(1, &secondFilterOutputTexture);
        secondFilterOutputTexture = 0;
    }
}

#pragma mark -
#pragma mark Managing the display FBOs

- (void)createFilterFBOofSize:(CGSize)currentFBOSize;
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
    }
    else
    {
        glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)currentFBOSize.width, (int)currentFBOSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, secondFilterOutputTexture, 0);
    }
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)destroyFilterFBO;
{
    [super destroyFilterFBO];
    
    if (secondFilterFramebuffer)
	{
		glDeleteFramebuffers(1, &secondFilterFramebuffer);
		secondFilterFramebuffer = 0;
	}	
}

- (void)setSecondFilterFBO;
{
    glBindFramebuffer(GL_FRAMEBUFFER, secondFilterFramebuffer);
//    
//    CGSize currentFBOSize = [self sizeOfFBO];
//    glViewport(0, 0, (int)currentFBOSize.width, (int)currentFBOSize.height);
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
    
    // Run the first stage of the two-pass filter
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates sourceTexture:sourceTexture];
    
    // Run the second stage of the two-pass filter
    [self setSecondFilterFBO];
    
    [secondFilterProgram use];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
	glActiveTexture(GL_TEXTURE3);
	glBindTexture(GL_TEXTURE_2D, outputTexture);
    
	glUniform1i(secondFilterInputTextureUniform, 3);	
    
    glVertexAttribPointer(secondFilterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
	glVertexAttribPointer(secondFilterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [[self class] textureCoordinatesForRotation:kGPUImageNoRotation]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)prepareForImageCapture;
{
    preparedToCaptureImage = YES;
    
    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        if (secondFilterOutputTexture)
        {
            glDeleteTextures(1, &secondFilterOutputTexture);
            secondFilterOutputTexture = 0;
        }
    }
}


@end

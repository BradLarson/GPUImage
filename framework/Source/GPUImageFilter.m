#import "GPUImageFilter.h"
#import "GPUImagePicture.h"

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

void dataProviderReleaseCallback (void *info, const void *data, size_t size);

@implementation GPUImageFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    [GPUImageOpenGLESContext useImageProcessingContext];
    filterProgram = [[GLProgram alloc] initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
    
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
    
    filterPositionAttribute = [filterProgram attributeIndex:@"position"];
    filterTextureCoordinateAttribute = [filterProgram attributeIndex:@"inputTextureCoordinate"];
    filterInputTextureUniform = [filterProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
    filterInputTextureUniform2 = [filterProgram uniformIndex:@"inputImageTexture2"]; // This does assume a name of "inputImageTexture2" for second input texture in the fragment shader

    [filterProgram use];    
	glEnableVertexAttribArray(filterPositionAttribute);
	glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    
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

- (UIImage *)imageFromCurrentlyProcessedOutput;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [self setOutputFBO];

    CGSize currentFBOSize = [self sizeOfFBO];

    NSUInteger totalBytesForImage = (int)currentFBOSize.width * (int)currentFBOSize.height * 4;
    GLubyte *rawImagePixels = (GLubyte *)malloc(totalBytesForImage);
    glReadPixels(0, 0, (int)currentFBOSize.width, (int)currentFBOSize.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);

    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rawImagePixels, totalBytesForImage, dataProviderReleaseCallback);
    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();

    CGImageRef cgImageFromBytes = CGImageCreate((int)currentFBOSize.width, (int)currentFBOSize.height, 8, 32, 4 * (int)currentFBOSize.width, defaultRGBColorSpace, kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    UIImage *finalImage = [UIImage imageWithCGImage:cgImageFromBytes scale:1.0 orientation:UIImageOrientationLeft];

    CGImageRelease(cgImageFromBytes);
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(defaultRGBColorSpace);
//    free(rawImagePixels);
    
    return finalImage;
}

- (UIImage *)imageByFilteringImage:(UIImage *)imageToFilter;
{
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:imageToFilter];
    
    [stillImageSource addTarget:self];
    [stillImageSource processImage];
    
    UIImage *processedImage = [self imageFromCurrentlyProcessedOutput];
    
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
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &filterFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, filterFramebuffer);
    
//    NSLog(@"Filter size: %f, %f", currentFBOSize.width, currentFBOSize.height);
    
    glBindTexture(GL_TEXTURE_2D, outputTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)currentFBOSize.width, (int)currentFBOSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outputTexture, 0);
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)destroyFilterFBO;
{
    if (filterFramebuffer)
	{
		glDeleteFramebuffers(1, &filterFramebuffer);
		filterFramebuffer = 0;
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

#pragma mark -
#pragma mark Rendering

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [self setFilterFBO];
    
    [filterProgram use];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, sourceTexture);

	glUniform1i(filterInputTextureUniform, 2);	

    if (filterSourceTexture2 != 0)
    {
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, filterSourceTexture2);
                
        glUniform1i(filterInputTextureUniform2, 3);	
    }
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
	glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);    
}

- (void)informTargetsAboutNewFrame;
{
    for (id<GPUImageInput> currentTarget in targets)
    {
        [currentTarget setInputSize:inputTextureSize];
        [currentTarget newFrameReady];
    }
}

#pragma mark -
#pragma mark Input parameters

- (void)setInteger:(GLint)newInteger forUniform:(NSString *)uniformName;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    
    glUniform1i(uniformIndex, newInteger);
}

- (void)setFloat:(GLfloat)newFloat forUniform:(NSString *)uniformName;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    
    glUniform1f(uniformIndex, newFloat);
}

- (void)setSize:(CGSize)newSize forUniform:(NSString *)uniformName;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    GLfloat sizeUniform[2];
    sizeUniform[0] = newSize.width;
    sizeUniform[1] = newSize.height;
    
    glUniform2fv(uniformIndex, 1, sizeUniform);
}

- (void)setPoint:(CGPoint)newPoint forUniform:(NSString *)uniformName;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    GLfloat sizeUniform[2];
    sizeUniform[0] = newPoint.x;
    sizeUniform[1] = newPoint.y;
    
    glUniform2fv(uniformIndex, 1, sizeUniform);
}

- (void)setFloatVec3:(GLfloat *)newVec3 forUniform:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [filterProgram use];
    
    glUniform3fv(uniformIndex, 1, newVec3);    
}

- (void)setFloatVec4:(GLfloat *)newVec4 forUniform:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [filterProgram use];
    
    glUniform4fv(uniformIndex, 1, newVec4);    
}

- (void)setFloatArray:(GLfloat *)array length:(GLsizei)count forUniform:(NSString*)uniformName {
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    
    glUniform1fv(uniformIndex, count, array);
}

#pragma mark -
#pragma mark GPUImageInput

- (void)newFrameReady;
{
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat squareTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f,  1.0f,
        1.0f,  1.0f,
    };
 
    [self renderToTextureWithVertices:squareVertices textureCoordinates:squareTextureCoordinates sourceTexture:filterSourceTexture];
    [self informTargetsAboutNewFrame];
}

- (NSInteger)nextAvailableTextureIndex;
{
    if (filterSourceTexture == 0)
    {
        return 0;
    }
    else
    {
        return 1;
    }
}

- (void)setInputTexture:(GLuint)newInputTexture atIndex:(NSInteger)textureIndex;
{
    if (textureIndex == 0)
    {
        filterSourceTexture = newInputTexture;
    }
    else
    {
        filterSourceTexture2 = newInputTexture;
    }
}

- (void)setInputSize:(CGSize)newSize;
{
    inputTextureSize = newSize;
}

- (CGSize)maximumOutputSize;
{
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
}

#pragma mark -
#pragma mark Accessors

@end

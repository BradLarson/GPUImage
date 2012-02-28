#import "GPUImageRawData.h"

#import "GPUImageOpenGLESContext.h"
#import "GLProgram.h"
#import "GPUImageFilter.h"

NSString *const kGPUImageDataFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);


@interface GPUImageRawData ()
{
    CGSize imageSize;
    BOOL hasReadFromTheCurrentFrame;
    
	GLuint dataFramebuffer, dataRenderbuffer;

    GLuint inputTextureForDisplay;
    
    GLProgram *dataProgram;
    GLint dataPositionAttribute, dataTextureCoordinateAttribute;
    GLint dataInputTextureUniform;
    
    GLubyte *_rawBytesForImage;
}

// Frame rendering
- (void)createDataFBO;
- (void)destroyDataFBO;
- (void)setFilterFBO;
- (void)presentFramebuffer;

- (void)renderAtInternalSize;

@end

@implementation GPUImageRawData

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithImageSize:(CGSize)newImageSize;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    imageSize = newImageSize;
    hasReadFromTheCurrentFrame = NO;
    _rawBytesForImage = NULL;

    [GPUImageOpenGLESContext useImageProcessingContext];
    dataProgram = [[GLProgram alloc] initWithVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageDataFragmentShaderString];
    
    [dataProgram addAttribute:@"position"];
	[dataProgram addAttribute:@"inputTextureCoordinate"];
    
    if (![dataProgram link])
	{
		NSString *progLog = [dataProgram programLog];
		NSLog(@"Program link log: %@", progLog); 
		NSString *fragLog = [dataProgram fragmentShaderLog];
		NSLog(@"Fragment shader compile log: %@", fragLog);
		NSString *vertLog = [dataProgram vertexShaderLog];
		NSLog(@"Vertex shader compile log: %@", vertLog);
		dataProgram = nil;
        NSAssert(NO, @"Filter shader link failed");
	}
    
    dataPositionAttribute = [dataProgram attributeIndex:@"position"];
    dataTextureCoordinateAttribute = [dataProgram attributeIndex:@"inputTextureCoordinate"];
    dataInputTextureUniform = [dataProgram uniformIndex:@"inputImageTexture"];
    
    [dataProgram use];    
	glEnableVertexAttribArray(dataPositionAttribute);
	glEnableVertexAttribArray(dataTextureCoordinateAttribute);

    return self;
}

- (void)dealloc
{
    if (_rawBytesForImage != NULL)
    {
        free(_rawBytesForImage);
        _rawBytesForImage = NULL;
    }
}

#pragma mark -
#pragma mark Frame rendering

- (void)createDataFBO;
{
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &dataFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, dataFramebuffer);

    glGenRenderbuffers(1, &dataRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, dataRenderbuffer);

    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, (int)imageSize.width, (int)imageSize.height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, dataRenderbuffer);	
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}

- (void)destroyDataFBO;
{
    if (dataFramebuffer)
	{
		glDeleteFramebuffers(1, &dataFramebuffer);
		dataFramebuffer = 0;
	}	

    if (dataRenderbuffer)
	{
		glDeleteRenderbuffers(1, &dataRenderbuffer);
		dataRenderbuffer = 0;
	}	
}

- (void)setFilterFBO;
{
    if (!dataFramebuffer)
    {
        [self createDataFBO];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, dataFramebuffer);
    
    glViewport(0, 0, (int)imageSize.width, (int)imageSize.height);
}

- (void)presentFramebuffer;
{
    glBindRenderbuffer(GL_RENDERBUFFER, dataRenderbuffer);
    [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] presentBufferForDisplay];
}

#pragma mark -
#pragma mark Data access

- (void)renderAtInternalSize;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [self setFilterFBO];
    
    [dataProgram use];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat textureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, inputTextureForDisplay);
	glUniform1i(dataInputTextureUniform, 4);	
    
    glVertexAttribPointer(dataPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
	glVertexAttribPointer(dataTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [self presentFramebuffer];
}

- (GPUByteColorVector)colorAtLocation:(CGPoint)locationInImage;
{
    GPUByteColorVector *imageColorBytes = (GPUByteColorVector *)self.rawBytesForImage;
//    NSLog(@"Row start");
//    for (unsigned int currentXPosition = 0; currentXPosition < (imageSize.width * 2.0); currentXPosition++)
//    {
//        GPUByteColorVector byteAtPosition = imageColorBytes[currentXPosition];
//        NSLog(@"%d - %d, %d, %d", currentXPosition, byteAtPosition.red, byteAtPosition.green, byteAtPosition.blue);
//    }
//    NSLog(@"Row end");
    
//    GPUByteColorVector byteAtOne = imageColorBytes[1];
//    GPUByteColorVector byteAtWidth = imageColorBytes[(int)imageSize.width - 3];
//    GPUByteColorVector byteAtHeight = imageColorBytes[(int)(imageSize.height - 1) * (int)imageSize.width];
//    NSLog(@"Byte 1: %d, %d, %d, byte 2: %d, %d, %d, byte 3: %d, %d, %d", byteAtOne.red, byteAtOne.green, byteAtOne.blue, byteAtWidth.red, byteAtWidth.green, byteAtWidth.blue, byteAtHeight.red, byteAtHeight.green, byteAtHeight.blue);
    
    CGPoint locationToPickFrom = CGPointZero;
    locationToPickFrom.x = MIN(MAX(locationInImage.x, 0.0), (imageSize.width - 1.0));
    locationToPickFrom.y = MIN(MAX((imageSize.height - locationInImage.y), 0.0), (imageSize.height - 1.0));
    
    return imageColorBytes[(int)(round((locationToPickFrom.y * imageSize.width) + locationToPickFrom.x))];
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReady;
{
    hasReadFromTheCurrentFrame = NO;

    [self.delegate newImageFrameAvailableFromDataSource:self];
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputTexture:(GLuint)newInputTexture atIndex:(NSInteger)textureIndex;
{
    inputTextureForDisplay = newInputTexture;
}

- (void)setInputSize:(CGSize)newSize;
{
}

- (CGSize)maximumOutputSize;
{
    return imageSize;
}

#pragma mark -
#pragma mark Accessors

@synthesize rawBytesForImage = _rawBytesForImage;
@synthesize delegate = _delegate;

- (GLubyte *)rawBytesForImage;
{
    if (_rawBytesForImage == NULL)
    {
        _rawBytesForImage = (GLubyte *) calloc(imageSize.width * imageSize.height * 4, sizeof(GLubyte));
        hasReadFromTheCurrentFrame = NO;
    }
    
    if (hasReadFromTheCurrentFrame)
    {
        return _rawBytesForImage;
    }
    else
    {
        [GPUImageOpenGLESContext useImageProcessingContext];
        [self renderAtInternalSize];
        glReadPixels(0, 0, imageSize.width, imageSize.height, GL_RGBA, GL_UNSIGNED_BYTE, _rawBytesForImage);

        return _rawBytesForImage;
    }
    
}

@end

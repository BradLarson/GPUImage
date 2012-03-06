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
    [super createFilterFBOofSize:currentFBOSize];
    
    glGenFramebuffers(1, &secondFilterFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, secondFilterFramebuffer);
    
    glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)currentFBOSize.width, (int)currentFBOSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, secondFilterOutputTexture, 0);
	
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
    // Override this for filters that have multiple framebuffers
    [self setSecondFilterFBO];
}

#pragma mark -
#pragma mark Rendering

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
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
    
    if (filterSourceTexture2 != 0)
    {
        glActiveTexture(GL_TEXTURE4);
        glBindTexture(GL_TEXTURE_2D, filterSourceTexture2);
        
        glUniform1i(secondFilterInputTextureUniform2, 4);
    }
    
    glVertexAttribPointer(secondFilterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
	glVertexAttribPointer(secondFilterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

@end

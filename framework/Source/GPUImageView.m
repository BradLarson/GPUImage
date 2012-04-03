#import "GPUImageView.h"
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageFilter.h"

#pragma mark -
#pragma mark Private methods and instance variables

@interface GPUImageView () 
{
    GLuint inputTextureForDisplay;
    GLuint displayRenderbuffer, displayFramebuffer;
    
    GLProgram *displayProgram;
    GLint displayPositionAttribute, displayTextureCoordinateAttribute;
    GLint displayInputTextureUniform;
}

// Initialization and teardown
- (void)commonInit;

// Managing the display FBOs
- (void)createDisplayFramebuffer;
- (void)destroyDisplayFramebuffer;

@end

@implementation GPUImageView

@synthesize sizeInPixels = _sizeInPixels;

#pragma mark -
#pragma mark Initialization and teardown

+ (Class)layerClass 
{
	return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
    {
		return nil;
    }
    
    [self commonInit];
    
    return self;
}

-(id)initWithCoder:(NSCoder *)coder
{
	if (!(self = [super initWithCoder:coder])) 
    {
        return nil;
	}

    [self commonInit];

	return self;
}

- (void)commonInit;
{
    // Set scaling to account for Retina display	
    if ([self respondsToSelector:@selector(setContentScaleFactor:)])
    {
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
    }

    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];		

    [GPUImageOpenGLESContext useImageProcessingContext];
    displayProgram = [[GLProgram alloc] initWithVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];

    [displayProgram addAttribute:@"position"];
	[displayProgram addAttribute:@"inputTextureCoordinate"];
    
    if (![displayProgram link])
	{
		NSString *progLog = [displayProgram programLog];
		NSLog(@"Program link log: %@", progLog); 
		NSString *fragLog = [displayProgram fragmentShaderLog];
		NSLog(@"Fragment shader compile log: %@", fragLog);
		NSString *vertLog = [displayProgram vertexShaderLog];
		NSLog(@"Vertex shader compile log: %@", vertLog);
		displayProgram = nil;
        NSAssert(NO, @"Filter shader link failed");
	}
    
    displayPositionAttribute = [displayProgram attributeIndex:@"position"];
    displayTextureCoordinateAttribute = [displayProgram attributeIndex:@"inputTextureCoordinate"];
    displayInputTextureUniform = [displayProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputTexture" for the fragment shader
    
    [displayProgram use];    
	glEnableVertexAttribArray(displayPositionAttribute);
	glEnableVertexAttribArray(displayTextureCoordinateAttribute);

    [self addObserver:self forKeyPath:@"frame" options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"frame"])
    {
        [self destroyDisplayFramebuffer];
        [self createDisplayFramebuffer];
    }
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"frame"];
    
    [self destroyDisplayFramebuffer];
}

#pragma mark -
#pragma mark Managing the display FBOs

- (void)createDisplayFramebuffer;
{
	glGenFramebuffers(1, &displayFramebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
	
	glGenRenderbuffers(1, &displayRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
	
	[[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context] renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
	
    GLint backingWidth, backingHeight;

	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    _sizeInPixels.width = (CGFloat)backingWidth;
    _sizeInPixels.height = (CGFloat)backingHeight;
    
//	NSLog(@"Backing width: %d, height: %d", backingWidth, backingHeight);

	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, displayRenderbuffer);
	
    GLuint framebufferCreationStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(framebufferCreationStatus == GL_FRAMEBUFFER_COMPLETE, @"Failure with display framebuffer generation");
}

- (void)destroyDisplayFramebuffer;
{
    if (displayFramebuffer)
	{
		glDeleteFramebuffers(1, &displayFramebuffer);
		displayFramebuffer = 0;
	}
	
	if (displayRenderbuffer)
	{
		glDeleteRenderbuffers(1, &displayRenderbuffer);
		displayRenderbuffer = 0;
	}
}

- (void)setDisplayFramebuffer;
{
    if (!displayFramebuffer)
    {
        [self createDisplayFramebuffer];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    
    glViewport(0, 0, (GLint)_sizeInPixels.width, (GLint)_sizeInPixels.height);
}

- (void)presentFramebuffer;
{
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] presentBufferForDisplay];
}

#pragma mark -
#pragma mark GPUInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [self setDisplayFramebuffer];
    
    [displayProgram use];
    
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
	glUniform1i(displayInputTextureUniform, 4);	
    
    glVertexAttribPointer(displayPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
	glVertexAttribPointer(displayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    [self presentFramebuffer];
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
    if ([self respondsToSelector:@selector(setContentScaleFactor:)])
    {
        CGSize pointSize = self.bounds.size;
        return CGSizeMake(self.contentScaleFactor * pointSize.width, self.contentScaleFactor * pointSize.height);
    }
    else
    {
        return self.bounds.size;
    }
}

- (void)endProcessing
{
}

- (BOOL)shouldIgnoreUpdatesToThisTarget;
{
    return NO;
}

#pragma mark -
#pragma mark Accessors

- (CGSize)sizeInPixels;
{
    if (CGSizeEqualToSize(_sizeInPixels, CGSizeZero))
    {
        return [self maximumOutputSize];
    }
    else
    {
        return _sizeInPixels;
    }
}

@end

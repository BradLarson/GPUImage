#import "GPUImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "GPUImageContext.h"
#import "GPUImageFilter.h"
#import <AVFoundation/AVFoundation.h>

#pragma mark -
#pragma mark Private methods and instance variables

@interface GPUImageView () 
{
    GLuint inputTextureForDisplay;
    
    GLProgram *displayProgram;
    GLint displayPositionAttribute, displayTextureCoordinateAttribute;
    GLint displayInputTextureUniform;
    
    CGSize inputImageSize;
    GLfloat imageVertices[8];
    GLfloat backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha;
}

// Initialization and teardown
- (void)commonInit;

// Managing the display FBOs
- (void)createDisplayFramebuffer;
- (void)destroyDisplayFramebuffer;

// Handling fill mode
- (void)recalculateViewGeometry;

@end

@implementation GPUImageView

@synthesize sizeInPixels = _sizeInPixels;
@synthesize fillMode = _fillMode;
@synthesize enabled;

#pragma mark -
#pragma mark Initialization and teardown

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
    [self setOpenGLContext:[[GPUImageContext sharedImageProcessingContext] context]];
    inputRotation = kGPUImageNoRotation;
    self.hidden = NO;

    self.enabled = YES;
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        displayProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
        if (!displayProgram.initialized)
        {
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
        }
        
        displayPositionAttribute = [displayProgram attributeIndex:@"position"];
        displayTextureCoordinateAttribute = [displayProgram attributeIndex:@"inputTextureCoordinate"];
        displayInputTextureUniform = [displayProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputTexture" for the fragment shader

        [GPUImageContext setActiveShaderProgram:displayProgram];
        glEnableVertexAttribArray(displayPositionAttribute);
        glEnableVertexAttribArray(displayTextureCoordinateAttribute);
        
        [self setBackgroundColorRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        _fillMode = kGPUImageFillModePreserveAspectRatio;
        [self createDisplayFramebuffer];
    });
        
    [self addObserver:self forKeyPath:@"frame" options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"frame"] && (!CGSizeEqualToSize(self.bounds.size, CGSizeZero)))
    {
        runSynchronouslyOnVideoProcessingQueue(^{
            [self destroyDisplayFramebuffer];
            [self createDisplayFramebuffer];
        });
    }
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"frame"];
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [self destroyDisplayFramebuffer];
    });
}

#pragma mark -
#pragma mark Managing the display FBOs

- (void)createDisplayFramebuffer;
{
    // Perhaps I'll use an FBO at some time later, but for now will render directly to the screen
    _sizeInPixels.width = self.bounds.size.width;
    _sizeInPixels.height = self.bounds.size.height;

//	NSLog(@"Backing width: %d, height: %d", backingWidth, backingHeight);
}

- (void)destroyDisplayFramebuffer;
{
    [GPUImageContext useImageProcessingContext];
}

- (void)setDisplayFramebuffer;
{
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    
    glViewport(0, 0, (GLint)_sizeInPixels.width, (GLint)_sizeInPixels.height);
}

- (void)presentFramebuffer;
{
    [[GPUImageContext sharedImageProcessingContext] presentBufferForDisplay];
}

- (void)reshape;
{
    _sizeInPixels.width = self.bounds.size.width;
    _sizeInPixels.height = self.bounds.size.height;
    [self recalculateViewGeometry];
    [self newFrameReadyAtTime:kCMTimeInvalid atIndex:0];
}

#pragma mark -
#pragma mark Handling fill mode

- (void)recalculateViewGeometry;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        CGFloat heightScaling, widthScaling;
        
        CGSize currentViewSize = self.bounds.size;
        
        //    CGFloat imageAspectRatio = inputImageSize.width / inputImageSize.height;
        //    CGFloat viewAspectRatio = currentViewSize.width / currentViewSize.height;
        
        CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(inputImageSize, self.bounds);
        
        switch(_fillMode)
        {
            case kGPUImageFillModeStretch:
            {
                widthScaling = 1.0;
                heightScaling = 1.0;
            }; break;
            case kGPUImageFillModePreserveAspectRatio:
            {
                widthScaling = insetRect.size.width / currentViewSize.width;
                heightScaling = insetRect.size.height / currentViewSize.height;
            }; break;
            case kGPUImageFillModePreserveAspectRatioAndFill:
            {
                //            CGFloat widthHolder = insetRect.size.width / currentViewSize.width;
                widthScaling = currentViewSize.height / insetRect.size.height;
                heightScaling = currentViewSize.width / insetRect.size.width;
            }; break;
        }
        
        imageVertices[0] = -widthScaling;
        imageVertices[1] = -heightScaling;
        imageVertices[2] = widthScaling;
        imageVertices[3] = -heightScaling;
        imageVertices[4] = -widthScaling;
        imageVertices[5] = heightScaling;
        imageVertices[6] = widthScaling;
        imageVertices[7] = heightScaling;
    });
    
//    static const GLfloat imageVertices[] = {
//        -1.0f, -1.0f,
//        1.0f, -1.0f,
//        -1.0f,  1.0f,
//        1.0f,  1.0f,
//    };
}

- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
{
    backgroundColorRed = redComponent;
    backgroundColorGreen = greenComponent;
    backgroundColorBlue = blueComponent;
    backgroundColorAlpha = alphaComponent;
}

+ (const GLfloat *)textureCoordinatesForRotation:(GPUImageRotationMode)rotationMode;
{
//    static const GLfloat noRotationTextureCoordinates[] = {
//        0.0f, 0.0f,
//        1.0f, 0.0f,
//        0.0f, 1.0f,
//        1.0f, 1.0f,
//    };
    
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };

    static const GLfloat rotateRightTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };

    static const GLfloat rotateLeftTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };
        
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
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

#pragma mark -
#pragma mark GPUInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:displayProgram];
        [self setDisplayFramebuffer];
        
        glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE4);
        glBindTexture(GL_TEXTURE_2D, inputTextureForDisplay);
        glUniform1i(displayInputTextureUniform, 4);
        
        glVertexAttribPointer(displayPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices);
        glVertexAttribPointer(displayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [GPUImageView textureCoordinatesForRotation:inputRotation]);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        [self presentFramebuffer];
    });
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputTexture:(GLuint)newInputTexture atIndex:(NSInteger)textureIndex;
{
    inputTextureForDisplay = newInputTexture;
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    inputRotation = newInputRotation;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        CGSize rotatedSize = newSize;
        
        if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
        {
            rotatedSize.width = newSize.height;
            rotatedSize.height = newSize.width;
        }
        
        if (!CGSizeEqualToSize(inputImageSize, rotatedSize))
        {
            inputImageSize = rotatedSize;
            [self recalculateViewGeometry];
        }
    });
}

- (CGSize)maximumOutputSize;
{
    if ([self respondsToSelector:@selector(setContentScaleFactor:)])
    {
        CGSize pointSize = self.bounds.size;
        // TODO: Account for Retina displays
        return pointSize;
//        return CGSizeMake(self.contentScaleFactor * pointSize.width, self.contentScaleFactor * pointSize.height);
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

- (void)setTextureDelegate:(id<GPUImageTextureDelegate>)newTextureDelegate atIndex:(NSInteger)textureIndex;
{
    textureDelegate = newTextureDelegate;
}

- (void)conserveMemoryForNextFrame;
{
    
}

- (BOOL)wantsMonochromeInput;
{
    return NO;
}

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
{
    
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

- (void)setFillMode:(GPUImageFillModeType)newValue;
{
    _fillMode = newValue;
    [self recalculateViewGeometry];
}

@end

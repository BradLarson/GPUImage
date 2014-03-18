#import "GPUImageRawDataOutput.h"

#import "GPUImageContext.h"
#import "GLProgram.h"
#import "GPUImageFilter.h"
#import "GPUImageMovieWriter.h"

@interface GPUImageRawDataOutput ()
{
    GPUImageFramebuffer *firstInputFramebuffer, *outputFramebuffer, *retainedFramebuffer;
    
    BOOL hasReadFromTheCurrentFrame;
    
    GLProgram *dataProgram;
    GLint dataPositionAttribute, dataTextureCoordinateAttribute;
    GLint dataInputTextureUniform;
    
    GLubyte *_rawBytesForImage;
    
    BOOL lockNextFramebuffer;
}

// Frame rendering
- (void)renderAtInternalSize;

@end

@implementation GPUImageRawDataOutput

@synthesize rawBytesForImage = _rawBytesForImage;
@synthesize newFrameAvailableBlock = _newFrameAvailableBlock;
@synthesize enabled;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    self.enabled = YES;
    lockNextFramebuffer = NO;
    outputBGRA = resultsInBGRAFormat;
    imageSize = newImageSize;
    hasReadFromTheCurrentFrame = NO;
    _rawBytesForImage = NULL;
    inputRotation = kGPUImageNoRotation;

    [GPUImageContext useImageProcessingContext];
    if ( (outputBGRA && ![GPUImageContext supportsFastTextureUpload]) || (!outputBGRA && [GPUImageContext supportsFastTextureUpload]) )
    {
        dataProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageColorSwizzlingFragmentShaderString];
    }
    else
    {
        dataProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
    }
 
    if (!dataProgram.initialized)
    {
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
    }
    
    dataPositionAttribute = [dataProgram attributeIndex:@"position"];
    dataTextureCoordinateAttribute = [dataProgram attributeIndex:@"inputTextureCoordinate"];
    dataInputTextureUniform = [dataProgram uniformIndex:@"inputImageTexture"];
    
    return self;
}

- (void)dealloc
{
    if (_rawBytesForImage != NULL && (![GPUImageContext supportsFastTextureUpload]))
    {
        free(_rawBytesForImage);
        _rawBytesForImage = NULL;
    }
}

#pragma mark -
#pragma mark Data access

- (void)renderAtInternalSize;
{
    [GPUImageContext setActiveShaderProgram:dataProgram];

    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:imageSize onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];

    if(lockNextFramebuffer)
    {
        retainedFramebuffer = outputFramebuffer;
        lockNextFramebuffer = NO;
    }

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
	glUniform1i(dataInputTextureUniform, 4);	
    
    glVertexAttribPointer(dataPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
	glVertexAttribPointer(dataTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glEnableVertexAttribArray(dataPositionAttribute);
	glEnableVertexAttribArray(dataTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [firstInputFramebuffer unlock];
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
    
    if (outputBGRA)    
    {
        GPUByteColorVector flippedColor = imageColorBytes[(int)(round((locationToPickFrom.y * imageSize.width) + locationToPickFrom.x))];
        GLubyte temporaryRed = flippedColor.red;
        
        flippedColor.red = flippedColor.blue;
        flippedColor.blue = temporaryRed;

        return flippedColor;
    }
    else
    {
        return imageColorBytes[(int)(round((locationToPickFrom.y * imageSize.width) + locationToPickFrom.x))];
    }
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    hasReadFromTheCurrentFrame = NO;
    
    if (_newFrameAvailableBlock != NULL)
    {
        _newFrameAvailableBlock();
    }
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
    return imageSize;
}

- (void)endProcessing;
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

#pragma mark -
#pragma mark Accessors

- (GLubyte *)rawBytesForImage;
{
    if ( (_rawBytesForImage == NULL) && (![GPUImageContext supportsFastTextureUpload]) )
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
        runSynchronouslyOnVideoProcessingQueue(^{
            // Note: the fast texture caches speed up 640x480 frame reads from 9.6 ms to 3.1 ms on iPhone 4S
            
            [GPUImageContext useImageProcessingContext];
            [self renderAtInternalSize];
            
            if ([GPUImageContext supportsFastTextureUpload])
            {
                glFinish();
                _rawBytesForImage = [outputFramebuffer byteBuffer];
            }
            else
            {
                glReadPixels(0, 0, imageSize.width, imageSize.height, GL_RGBA, GL_UNSIGNED_BYTE, _rawBytesForImage);
                // GL_EXT_read_format_bgra
                //            glReadPixels(0, 0, imageSize.width, imageSize.height, GL_BGRA_EXT, GL_UNSIGNED_BYTE, _rawBytesForImage);
            }
          
            hasReadFromTheCurrentFrame = YES;

        });
        
        return _rawBytesForImage;
    }
}

- (NSUInteger)bytesPerRowInOutput;
{
    return [retainedFramebuffer bytesPerRow];
}

- (void)setImageSize:(CGSize)newImageSize {
    imageSize = newImageSize;
    if (_rawBytesForImage != NULL && (![GPUImageContext supportsFastTextureUpload]))
    {
        free(_rawBytesForImage);
        _rawBytesForImage = NULL;
    }
}

- (void)lockFramebufferForReading;
{
    lockNextFramebuffer = YES;
}

- (void)unlockFramebufferAfterReading;
{
    [retainedFramebuffer unlock];
    retainedFramebuffer = nil;
}

@end

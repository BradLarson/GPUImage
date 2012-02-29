#import "GPUImageMovieWriter.h"

#import "GPUImageOpenGLESContext.h"
#import "GLProgram.h"
#import "GPUImageFilter.h"

NSString *const kGPUImageColorSwizzlingFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate).bgra;
 }
);


@interface GPUImageMovieWriter ()
{
    GLuint movieFramebuffer, movieRenderbuffer;
    
    GLProgram *colorSwizzlingProgram;
    GLint colorSwizzlingPositionAttribute, colorSwizzlingTextureCoordinateAttribute;
    GLint colorSwizzlingInputTextureUniform;

    GLuint inputTextureForMovieRendering;
    
    GLubyte *frameData;
    
    NSDate *startTime;
}

// Movie recording
- (void)initializeMovie;

// Frame rendering
- (void)createDataFBO;
- (void)destroyDataFBO;
- (void)setFilterFBO;
- (void)presentFramebuffer;

- (void)renderAtInternalSize;

@end

@implementation GPUImageMovieWriter

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    videoSize = newSize;
    movieURL = newMovieURL;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    colorSwizzlingProgram = [[GLProgram alloc] initWithVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageColorSwizzlingFragmentShaderString];
    
    [colorSwizzlingProgram addAttribute:@"position"];
	[colorSwizzlingProgram addAttribute:@"inputTextureCoordinate"];
    
    if (![colorSwizzlingProgram link])
	{
		NSString *progLog = [colorSwizzlingProgram programLog];
		NSLog(@"Program link log: %@", progLog); 
		NSString *fragLog = [colorSwizzlingProgram fragmentShaderLog];
		NSLog(@"Fragment shader compile log: %@", fragLog);
		NSString *vertLog = [colorSwizzlingProgram vertexShaderLog];
		NSLog(@"Vertex shader compile log: %@", vertLog);
		colorSwizzlingProgram = nil;
        NSAssert(NO, @"Filter shader link failed");
	}
    
    colorSwizzlingPositionAttribute = [colorSwizzlingProgram attributeIndex:@"position"];
    colorSwizzlingTextureCoordinateAttribute = [colorSwizzlingProgram attributeIndex:@"inputTextureCoordinate"];
    colorSwizzlingInputTextureUniform = [colorSwizzlingProgram uniformIndex:@"inputImageTexture"];
    
    [colorSwizzlingProgram use];    
	glEnableVertexAttribArray(colorSwizzlingPositionAttribute);
	glEnableVertexAttribArray(colorSwizzlingTextureCoordinateAttribute);
    
    [self initializeMovie];

    return self;
}

- (void)dealloc;
{
    if (frameData != NULL)
    {
        free(frameData);
    }
}

#pragma mark -
#pragma mark Movie recording

- (void)initializeMovie;
{
    frameData = (GLubyte *) malloc((int)videoSize.width * (int)videoSize.height * 4);

//    frameData = (GLubyte *) calloc(videoSize.width * videoSize.height * 4, sizeof(GLubyte));

    NSError *error = nil;
    
    assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:AVFileTypeAppleM4V error:&error];
//    assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
    
    
    NSMutableDictionary * outputSettings = [[NSMutableDictionary alloc] init];
    [outputSettings setObject: AVVideoCodecH264 forKey: AVVideoCodecKey];
    [outputSettings setObject: [NSNumber numberWithInt: videoSize.width] forKey: AVVideoWidthKey];
    [outputSettings setObject: [NSNumber numberWithInt: videoSize.height] forKey: AVVideoHeightKey];
    
/*    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] init];
    [compressionProperties setObject: [NSNumber numberWithInt: 1000000] forKey: AVVideoAverageBitRateKey];
    [compressionProperties setObject: [NSNumber numberWithInt: 16] forKey: AVVideoMaxKeyFrameIntervalKey];
    [compressionProperties setObject: AVVideoProfileLevelH264Main31 forKey: AVVideoProfileLevelKey];
    
    [outputSettings setObject: compressionProperties forKey: AVVideoCompressionPropertiesKey];*/
    
    assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    //writerInput.expectsMediaDataInRealTime = NO;
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                                           [NSNumber numberWithInt:videoSize.width], kCVPixelBufferWidthKey,
                                                           [NSNumber numberWithInt:videoSize.height], kCVPixelBufferHeightKey,
                                                           nil];
//    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,
//                                                           nil];
        
    assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    [assetWriter addInput:assetWriterVideoInput];
}

- (void)startRecording;
{
    startTime = [NSDate date];
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
}

- (void)finishRecording;
{
    [assetWriterVideoInput markAsFinished];
    [assetWriter finishWriting];    
}

#pragma mark -
#pragma mark Frame rendering

- (void)createDataFBO;
{
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &movieFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    
    glGenRenderbuffers(1, &movieRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, movieRenderbuffer);
    
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, (int)videoSize.width, (int)videoSize.height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, movieRenderbuffer);	
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}

- (void)destroyDataFBO;
{
    if (movieFramebuffer)
	{
		glDeleteFramebuffers(1, &movieFramebuffer);
		movieFramebuffer = 0;
	}	
    
    if (movieRenderbuffer)
	{
		glDeleteRenderbuffers(1, &movieRenderbuffer);
		movieRenderbuffer = 0;
	}	
}

- (void)setFilterFBO;
{
    if (!movieFramebuffer)
    {
        [self createDataFBO];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    
    glViewport(0, 0, (int)videoSize.width, (int)videoSize.height);
}

- (void)presentFramebuffer;
{
    glBindRenderbuffer(GL_RENDERBUFFER, movieRenderbuffer);
    [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] presentBufferForDisplay];
}

- (void)renderAtInternalSize;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [self setFilterFBO];
    
    [colorSwizzlingProgram use];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // This needs to be flipped to write out to video correctly
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
	glBindTexture(GL_TEXTURE_2D, inputTextureForMovieRendering);
	glUniform1i(colorSwizzlingInputTextureUniform, 4);	
    
    glVertexAttribPointer(colorSwizzlingPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
	glVertexAttribPointer(colorSwizzlingTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [self presentFramebuffer];
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReady;
{
    if (!assetWriterVideoInput.readyForMoreMediaData)
    {
//        NSLog(@"Had to drop a frame");
        return;
    }

    // Render the frame with swizzled colors, so that they can be uploaded quickly as BGRA frames
    [GPUImageOpenGLESContext useImageProcessingContext];
    [self renderAtInternalSize];

    CVPixelBufferRef pixel_buffer = NULL;

    CVReturn status = CVPixelBufferPoolCreatePixelBuffer (NULL, [assetWriterPixelBufferInput pixelBufferPool], &pixel_buffer);
    if ((pixel_buffer == NULL) || (status != kCVReturnSuccess))
    {
        return;
//        NSLog(@"Couldn't pull pixel buffer from pool");
//        glReadPixels(0, 0, videoSize.width, videoSize.height, GL_RGBA, GL_UNSIGNED_BYTE, frameData);
//
//        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, 
//                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
//
//        CFDictionaryRef optionsDictionary = (__bridge_retained CFDictionaryRef)options;
//        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, (int)videoSize.width, (int)videoSize.height, kCVPixelFormatType_32BGRA, frameData, 4 * (int)videoSize.width, NULL, 0, optionsDictionary, &pixel_buffer);
//        CFRelease(optionsDictionary);
//        CVPixelBufferLockBaseAddress(pixel_buffer, 0);
    }
    else
    {
        CVPixelBufferLockBaseAddress(pixel_buffer, 0);
        
//        NSLog(@"Grabbing pixel buffer");


        GLubyte *pixelBufferData = (GLubyte *)CVPixelBufferGetBaseAddress(pixel_buffer);
        glReadPixels(0, 0, videoSize.width, videoSize.height, GL_RGBA, GL_UNSIGNED_BYTE, pixelBufferData);
    }
    
    // May need to add a check here, because if two consecutive times with the same value are added to the movie, it aborts recording
    CMTime currentTime = CMTimeMakeWithSeconds([[NSDate date] timeIntervalSinceDate:startTime],120);
    
    if(![assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:currentTime]) 
    {
        NSLog(@"Problem appending pixel buffer at time: %lld", currentTime.value);
    } 
    else 
    {
//        NSLog(@"Recorded pixel buffer at time: %lld", currentTime.value);
    }
    CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
    
    CVPixelBufferRelease(pixel_buffer);
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputTexture:(GLuint)newInputTexture atIndex:(NSInteger)textureIndex;
{
    inputTextureForMovieRendering = newInputTexture;
}

- (void)setInputSize:(CGSize)newSize;
{
}

- (CGSize)maximumOutputSize;
{
    return CGSizeZero;
}

@end

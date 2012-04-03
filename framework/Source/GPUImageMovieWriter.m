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
    
    CMTime startTime;
}

// Movie recording
- (void)initializeMovie;

// Frame rendering
- (void)createDataFBO;
- (void)destroyDataFBO;
- (void)setFilterFBO;

- (void)renderAtInternalSize;

@end

@implementation GPUImageMovieWriter
@synthesize CompletionBlock;
@synthesize FailureBlock;
@synthesize delegate;

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
    startTime = kCMTimeInvalid;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    
    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        colorSwizzlingProgram = [[GLProgram alloc] initWithVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
    }
    else
    {
        colorSwizzlingProgram = [[GLProgram alloc] initWithVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageColorSwizzlingFragmentShaderString];
    }
    
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
    
//    assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:AVFileTypeAppleM4V error:&error];
    assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
        if (FailureBlock) {
            FailureBlock(error);
        }
        else {
            if(self.delegate&&[self.delegate respondsToSelector:@selector(Failed:)]){
                [self.delegate Failed:error];
            }
        }
    }
    
    
    NSMutableDictionary * outputSettings = [[NSMutableDictionary alloc] init];
    [outputSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [outputSettings setObject:[NSNumber numberWithInt:videoSize.width] forKey:AVVideoWidthKey];
    [outputSettings setObject:[NSNumber numberWithInt:videoSize.height] forKey:AVVideoHeightKey];

    /*
    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:videoSize.width], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:videoSize.height], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:0], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:0], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];

    NSDictionary *videoAspectRatioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioHorizontalSpacingKey,
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioVerticalSpacingKey,
                                              nil];

    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] init];
    [compressionProperties setObject:videoCleanApertureSettings forKey:AVVideoCleanApertureKey];
    [compressionProperties setObject:videoAspectRatioSettings forKey:AVVideoPixelAspectRatioKey];
    [compressionProperties setObject:[NSNumber numberWithInt: 2000000] forKey:AVVideoAverageBitRateKey];
    [compressionProperties setObject:[NSNumber numberWithInt: 16] forKey:AVVideoMaxKeyFrameIntervalKey];
    [compressionProperties setObject:AVVideoProfileLevelH264Main31 forKey:AVVideoProfileLevelKey];
    
    [outputSettings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
    */
     
    assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    //writerInput.expectsMediaDataInRealTime = NO;
    
    // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
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
    startTime = kCMTimeInvalid;
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
    
    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &coreVideoTextureCache);
        if (err) 
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d");
        }

        // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
        

        CVPixelBufferPoolCreatePixelBuffer (NULL, [assetWriterPixelBufferInput pixelBufferPool], &renderTarget);

        CVOpenGLESTextureRef renderTexture;
        CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, coreVideoTextureCache, renderTarget,
                                                      NULL, // texture attributes
                                                      GL_TEXTURE_2D,
                                                      GL_RGBA, // opengl format
                                                      (int)videoSize.width,
                                                      (int)videoSize.height,
                                                      GL_BGRA, // native iOS format
                                                      GL_UNSIGNED_BYTE,
                                                      0,
                                                      &renderTexture);
        
        glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    }
    else
    {
        glGenRenderbuffers(1, &movieRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, movieRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, (int)videoSize.width, (int)videoSize.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, movieRenderbuffer);	
    }
    
	
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

- (void)renderAtInternalSize;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [self setFilterFBO];
    
    [colorSwizzlingProgram use];
    
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
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
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime;
{
    if (!assetWriterVideoInput.readyForMoreMediaData)
    {
//        NSLog(@"Had to drop a frame");
        return;
    }
    
    if (CMTIME_IS_INVALID(frameTime))
    {
        // Drop frames forced by images and other things with no time constants
        return;
    }

    // Render the frame with swizzled colors, so that they can be uploaded quickly as BGRA frames
    [GPUImageOpenGLESContext useImageProcessingContext];
    [self renderAtInternalSize];

    CVPixelBufferRef pixel_buffer = NULL;

    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        pixel_buffer = renderTarget; 
        CVPixelBufferLockBaseAddress(pixel_buffer, 0);
    }
    else
    {
        CVReturn status = CVPixelBufferPoolCreatePixelBuffer (NULL, [assetWriterPixelBufferInput pixelBufferPool], &pixel_buffer);
        if ((pixel_buffer == NULL) || (status != kCVReturnSuccess))
        {
            return;
        }
        else
        {
            CVPixelBufferLockBaseAddress(pixel_buffer, 0);
            
            GLubyte *pixelBufferData = (GLubyte *)CVPixelBufferGetBaseAddress(pixel_buffer);
            glReadPixels(0, 0, videoSize.width, videoSize.height, GL_RGBA, GL_UNSIGNED_BYTE, pixelBufferData);
        }
    }
    
    // May need to add a check here, because if two consecutive times with the same value are added to the movie, it aborts recording
    
//    CMTime currentTime = CMTimeMakeWithSeconds([[NSDate date] timeIntervalSinceDate:startTime],120);
    
    if (CMTIME_IS_INVALID(startTime))
    {
        startTime = frameTime;
    }
    
    if(![assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:CMTimeSubtract(frameTime, startTime)]) 
    {
        NSLog(@"Problem appending pixel buffer at time: %lld", frameTime.value);
    } 
    else 
    {
//        CMTime testTime = CMTimeSubtract(frameTime, startTime);
//        
//        NSLog(@"Recorded pixel buffer at time: %lld, %lld", frameTime.value, testTime.value);
    }
    CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
    
    if (![GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        CVPixelBufferRelease(pixel_buffer);
    }
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
    return videoSize;
}

- (void)endProcessing 
{
    if (CompletionBlock) {
        CompletionBlock();
    }
    else {
        if(self.delegate&&[delegate respondsToSelector:@selector(Completed)]){
            [self.delegate Completed];
        }
    }
}

- (BOOL)shouldIgnoreUpdatesToThisTarget;
{
    return NO;
}

@end

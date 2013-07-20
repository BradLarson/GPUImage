#import "GPUImageMovieWriter.h"

#import "GPUImageContext.h"
#import "GLProgram.h"
#import "GPUImageFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageColorSwizzlingFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate).bgra;
 }
 );
#else
NSString *const kGPUImageColorSwizzlingFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate).bgra;
 }
 );
#endif


@interface GPUImageMovieWriter ()
{
    GLuint movieFramebuffer, movieRenderbuffer;
    
    GLProgram *colorSwizzlingProgram;
    GLint colorSwizzlingPositionAttribute, colorSwizzlingTextureCoordinateAttribute;
    GLint colorSwizzlingInputTextureUniform;

    GLuint inputTextureForMovieRendering;
    
    GLubyte *frameData;
    
    CMTime startTime, previousFrameTime;
    
    BOOL isRecording;
}

// Movie recording
- (void)initializeMovieWithOutputSettings:(NSMutableDictionary *)outputSettings;

// Frame rendering
- (void)createDataFBO;
- (void)destroyDataFBO;
- (void)setFilterFBO;

- (void)renderAtInternalSize;

@end

@implementation GPUImageMovieWriter

@synthesize hasAudioTrack = _hasAudioTrack;
@synthesize encodingLiveVideo = _encodingLiveVideo;
@synthesize shouldPassthroughAudio = _shouldPassthroughAudio;
@synthesize completionBlock;
@synthesize failureBlock;
@synthesize videoInputReadyCallback;
@synthesize audioInputReadyCallback;
@synthesize enabled;

@synthesize delegate = _delegate;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize;
{
    return [self initWithMovieURL:newMovieURL size:newSize fileType:AVFileTypeQuickTimeMovie outputSettings:nil];
}

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize fileType:(NSString *)newFileType outputSettings:(NSMutableDictionary *)outputSettings;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    self.enabled = YES;
    
    videoSize = newSize;
    movieURL = newMovieURL;
    fileType = newFileType;
    startTime = kCMTimeInvalid;
    _encodingLiveVideo = YES;
    previousFrameTime = kCMTimeNegativeInfinity;
    inputRotation = kGPUImageNoRotation;

    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        if ([GPUImageContext supportsFastTextureUpload])
        {
            colorSwizzlingProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
        }
        else
        {
            colorSwizzlingProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageColorSwizzlingFragmentShaderString];
        }
        
        if (!colorSwizzlingProgram.initialized)
        {
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
        }        
        
        colorSwizzlingPositionAttribute = [colorSwizzlingProgram attributeIndex:@"position"];
        colorSwizzlingTextureCoordinateAttribute = [colorSwizzlingProgram attributeIndex:@"inputTextureCoordinate"];
        colorSwizzlingInputTextureUniform = [colorSwizzlingProgram uniformIndex:@"inputImageTexture"];
        
        // REFACTOR: Wrap this in a block for the image processing queue
        [GPUImageContext setActiveShaderProgram:colorSwizzlingProgram];
        
        glEnableVertexAttribArray(colorSwizzlingPositionAttribute);
        glEnableVertexAttribArray(colorSwizzlingTextureCoordinateAttribute);
    });
        
    [self initializeMovieWithOutputSettings:outputSettings];

    return self;
}

- (void)dealloc;
{
    [self destroyDataFBO];

    if (frameData != NULL)
    {
        free(frameData);
    }
}

#pragma mark -
#pragma mark Movie recording

- (void)initializeMovieWithOutputSettings:(NSMutableDictionary *)outputSettings;
{
    isRecording = NO;
    
    self.enabled = YES;
    frameData = (GLubyte *) malloc((int)videoSize.width * (int)videoSize.height * 4);

//    frameData = (GLubyte *) calloc(videoSize.width * videoSize.height * 4, sizeof(GLubyte));
    NSError *error = nil;
    assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:fileType error:&error];
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
        if (failureBlock) 
        {
            failureBlock(error);
        }
        else 
        {
            if(self.delegate && [self.delegate respondsToSelector:@selector(movieRecordingFailedWithError:)])
            {
                [self.delegate movieRecordingFailedWithError:error];
            }
        }
    }
    
    // Set this to make sure that a functional movie is produced, even if the recording is cut off mid-stream. Only the last second should be lost in that case.
    assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, 1000);
    
    // use default output settings if none specified
    if (outputSettings == nil) 
    {
        outputSettings = [[NSMutableDictionary alloc] init];
        [outputSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
        [outputSettings setObject:[NSNumber numberWithInt:videoSize.width] forKey:AVVideoWidthKey];
        [outputSettings setObject:[NSNumber numberWithInt:videoSize.height] forKey:AVVideoHeightKey];
    }
    // custom output settings specified
    else 
    {
		NSString *videoCodec = [outputSettings objectForKey:AVVideoCodecKey];
		NSNumber *width = [outputSettings objectForKey:AVVideoWidthKey];
		NSNumber *height = [outputSettings objectForKey:AVVideoHeightKey];
		
		NSAssert(videoCodec && width && height, @"OutputSettings is missing required parameters.");
    }
    
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
    assetWriterVideoInput.expectsMediaDataInRealTime = _encodingLiveVideo;
    
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
    isRecording = YES;
    startTime = kCMTimeInvalid;
	//    [assetWriter startWriting];
    
	//    [assetWriter startSessionAtSourceTime:kCMTimeZero];
}

- (void)startRecordingInOrientation:(CGAffineTransform)orientationTransform;
{
	assetWriterVideoInput.transform = orientationTransform;

	[self startRecording];
}

- (void)cancelRecording;
{
    if (assetWriter.status == AVAssetWriterStatusCompleted)
    {
        return;
    }
    
    isRecording = NO;
    runOnMainQueueWithoutDeadlocking(^{
        [assetWriterVideoInput markAsFinished];
        [assetWriterAudioInput markAsFinished];
        [assetWriter cancelWriting];
    });
}

- (void)finishRecording;
{
    [self finishRecordingWithCompletionHandler:nil];
}

- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler;
{
    if (assetWriter.status == AVAssetWriterStatusCompleted)
    {
        return;
    }

    isRecording = NO;
    runOnMainQueueWithoutDeadlocking(^{
        [assetWriterVideoInput markAsFinished];
        [assetWriterAudioInput markAsFinished];
#if (!defined(__IPHONE_6_0) || (__IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0))
        // Not iOS 6 SDK
        [assetWriter finishWriting];
        if (handler) handler();
#else
        // iOS 6 SDK
        if ([assetWriter respondsToSelector:@selector(finishWritingWithCompletionHandler:)]) {
            // Running iOS 6
            [assetWriter finishWritingWithCompletionHandler:(handler ?: ^{ })];
        }
        else {
            // Not running iOS 6
            [assetWriter finishWriting];
            if (handler) handler();
        }
#endif
    });
}

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer;
{
    if (!isRecording)
    {
        return;
    }
    
    if (_hasAudioTrack)
    {
        CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(audioBuffer);
        
        if (CMTIME_IS_INVALID(startTime))
        {
            if (audioInputReadyCallback == NULL)
            {
                [assetWriter startWriting];
            }
            [assetWriter startSessionAtSourceTime:currentSampleTime];
            startTime = currentSampleTime;
        }

        if (!assetWriterAudioInput.readyForMoreMediaData)
        {
            NSLog(@"Had to drop an audio frame");
            return;
        }
        
//        NSLog(@"Recorded audio sample time: %lld, %d, %lld", currentSampleTime.value, currentSampleTime.timescale, currentSampleTime.epoch);
        [assetWriterAudioInput appendSampleBuffer:audioBuffer];
    }
}

- (void)enableSynchronizationCallbacks;
{
    if (videoInputReadyCallback != NULL)
    {
        [assetWriter startWriting];
        [assetWriterVideoInput requestMediaDataWhenReadyOnQueue:[GPUImageContext sharedContextQueue] usingBlock:videoInputReadyCallback];
    }
    
    if (audioInputReadyCallback != NULL)
    {
        [assetWriterAudioInput requestMediaDataWhenReadyOnQueue:[GPUImageContext sharedContextQueue] usingBlock:audioInputReadyCallback];
    }        
    
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
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, (int)videoSize.width, (int)videoSize.height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, movieRenderbuffer);	
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}

- (void)destroyDataFBO;
{
    [GPUImageContext useImageProcessingContext];

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
    [GPUImageContext useImageProcessingContext];
    [self setFilterFBO];
    
    [GPUImageContext setActiveShaderProgram:colorSwizzlingProgram];
    
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
    
    glFinish();
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    if (!isRecording)
    {
        return;
    }

    // Drop frames forced by images and other things with no time constants
    // Also, if two consecutive times with the same value are added to the movie, it aborts recording, so I bail on that case
    if ( (CMTIME_IS_INVALID(frameTime)) || (CMTIME_COMPARE_INLINE(frameTime, ==, previousFrameTime)) || (CMTIME_IS_INDEFINITE(frameTime)) ) 
    {
        return;
    }

    if (CMTIME_IS_INVALID(startTime))
    {
        if (videoInputReadyCallback == NULL)
        {
            [assetWriter startWriting];
        }
        
        [assetWriter startSessionAtSourceTime:frameTime];
        startTime = frameTime;
    }

    if (!assetWriterVideoInput.readyForMoreMediaData)
    {
        NSLog(@"Had to drop a video frame");
        return;
    }
    
    // Render the frame with swizzled colors, so that they can be uploaded quickly as BGRA frames
    [GPUImageContext useImageProcessingContext];
    [self renderAtInternalSize];

    CVPixelBufferRef pixel_buffer = NULL;

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
    
//    if(![assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:CMTimeSubtract(frameTime, startTime)]) 
    if(![assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:frameTime]) 
    {
        NSLog(@"Problem appending pixel buffer at time: %lld", frameTime.value);
    } 
    else 
    {
//        NSLog(@"Recorded video sample time: %lld, %d, %lld", frameTime.value, frameTime.timescale, frameTime.epoch);
    }
    CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
    
    previousFrameTime = frameTime;
    
    if (![GPUImageContext supportsFastTextureUpload])
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

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    inputRotation = newInputRotation;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
}

- (CGSize)maximumOutputSize;
{
    return videoSize;
}

- (void)endProcessing 
{
    if (completionBlock) 
    {
        completionBlock();
    }
    else 
    {
        if (_delegate && [_delegate respondsToSelector:@selector(movieRecordingCompleted)])
        {
            [_delegate movieRecordingCompleted];
        }
    }
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

- (void)setHasAudioTrack:(BOOL)newValue
{
	[self setHasAudioTrack:newValue audioSettings:nil];
}

- (void)setHasAudioTrack:(BOOL)newValue audioSettings:(NSDictionary *)audioOutputSettings;
{
    _hasAudioTrack = newValue;
    
    if (_hasAudioTrack)
    {
        if (_shouldPassthroughAudio)
        {
			// Do not set any settings so audio will be the same as passthrough
			audioOutputSettings = nil;
        }
        else if (audioOutputSettings == nil)
        {
//            double preferredHardwareSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];
            double preferredHardwareSampleRate = 48000; // ? - TODO: Fix this, because it's probably broken
            
            AudioChannelLayout acl;
            bzero( &acl, sizeof(acl));
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
            
            audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                         [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                                         [ NSNumber numberWithFloat: preferredHardwareSampleRate ], AVSampleRateKey,
                                         [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                         //[ NSNumber numberWithInt:AVAudioQualityLow], AVEncoderAudioQualityKey,
                                         [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                         nil];
/*
            AudioChannelLayout acl;
            bzero( &acl, sizeof(acl));
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
            
            audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                                   [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                                   [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                                   [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                   [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                   nil];*/
        }
        
        assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
        [assetWriter addInput:assetWriterAudioInput];
        assetWriterAudioInput.expectsMediaDataInRealTime = _encodingLiveVideo;
    }
    else
    {
        // Remove audio track if it exists
    }
}


@end

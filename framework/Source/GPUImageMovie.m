#import "GPUImageMovie.h"
#import "GPUImageMovieWriter.h"

@interface GPUImageMovie ()
{
    BOOL audioEncodingIsFinished, videoEncodingIsFinished;
    GPUImageMovieWriter *synchronizedMovieWriter;
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
    AVAssetReader *reader;
}

- (void)processAsset;

@end

@implementation GPUImageMovie

@synthesize url = _url;
@synthesize asset = _asset;
@synthesize runBenchmark = _runBenchmark;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithURL:(NSURL *)url;
{
    if (!(self = [super init])) 
    {
        return nil;
    }

    [self textureCacheSetup];

    self.url = url;
    self.asset = nil;

    return self;
}

- (id)initWithAsset:(AVAsset *)asset;
{
    if (!(self = [super init])) 
    {
      return nil;
    }
    
    [self textureCacheSetup];

    self.url = nil;
    self.asset = asset;

    return self;
}

- (void)textureCacheSetup;
{
    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageOpenGLESContext useImageProcessingContext];
#if defined(__IPHONE_6_0)
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &coreVideoTextureCache);
#else
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &coreVideoTextureCache);
#endif
            if (err)
            {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
            }
            
            // Need to remove the initially created texture
            [self deleteOutputTexture];
        });
    }
}

- (void)dealloc
{
    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        CFRelease(coreVideoTextureCache);
    }
}
#pragma mark -
#pragma mark Movie processing

- (void)enableSynchronizedEncodingUsingMovieWriter:(GPUImageMovieWriter *)movieWriter;
{
    synchronizedMovieWriter = movieWriter;
    movieWriter.encodingLiveVideo = NO;
}

- (void)startProcessing
{
    if(self.url == nil) {
      [self processAsset];
      return;
    }
  
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:self.url options:inputOptions];    
    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
        NSError *error = nil;
        AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
        if (!tracksStatus == AVKeyValueStatusLoaded) 
        {
            return;
        }
        self.asset = inputAsset;
        [self processAsset];
    }];
}

- (void)processAsset
{
    __unsafe_unretained GPUImageMovie *weakSelf = self;
    NSError *error = nil;
    reader = [AVAssetReader assetReaderWithAsset:self.asset error:&error];

    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    [outputSettings setObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]  forKey: (NSString*)kCVPixelBufferPixelFormatTypeKey];
    // Maybe set alwaysCopiesSampleData to NO on iOS 5.0 for faster video decoding
    AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[self.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
    [reader addOutput:readerVideoTrackOutput];

    NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
    BOOL shouldRecordAudioTrack = (([audioTracks count] > 0) && (weakSelf.audioEncodingTarget != nil) );
    AVAssetReaderTrackOutput *readerAudioTrackOutput = nil;

    if (shouldRecordAudioTrack)
    {
        audioEncodingIsFinished = NO;

        // This might need to be extended to handle movies with more than one audio track
        AVAssetTrack* audioTrack = [audioTracks objectAtIndex:0];
        readerAudioTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
        [reader addOutput:readerAudioTrackOutput];
    }

    if ([reader startReading] == NO) 
    {
            NSLog(@"Error reading from file at URL: %@", weakSelf.url);
        return;
    }
        
    if (synchronizedMovieWriter != nil)
    {
        [synchronizedMovieWriter setVideoInputReadyCallback:^{
            [weakSelf readNextVideoFrameFromOutput:readerVideoTrackOutput];
        }];

        [synchronizedMovieWriter setAudioInputReadyCallback:^{
            [weakSelf readNextAudioSampleFromOutput:readerAudioTrackOutput];
        }];

        [synchronizedMovieWriter enableSynchronizationCallbacks];
    }
    else
    {
        while (reader.status == AVAssetReaderStatusReading) 
        {
                [weakSelf readNextVideoFrameFromOutput:readerVideoTrackOutput];

            if ( (shouldRecordAudioTrack) && (!audioEncodingIsFinished) )
            {
                    [weakSelf readNextAudioSampleFromOutput:readerAudioTrackOutput];
            }

        }

        if (reader.status == AVAssetWriterStatusCompleted) {
                [weakSelf endProcessing];
        }
    }
}

- (void)readNextVideoFrameFromOutput:(AVAssetReaderTrackOutput *)readerVideoTrackOutput;
{
    if (reader.status == AVAssetReaderStatusReading)
    {
        CMSampleBufferRef sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
        if (sampleBufferRef) 
        {
            __unsafe_unretained GPUImageMovie *weakSelf = self;
            runSynchronouslyOnVideoProcessingQueue(^{
                [weakSelf processMovieFrame:sampleBufferRef];
            });
            
            CMSampleBufferInvalidate(sampleBufferRef);
            CFRelease(sampleBufferRef);
        }
        else
        {
            videoEncodingIsFinished = YES;
            [self endProcessing];
        }
    }
    else if (synchronizedMovieWriter != nil)
    {
        if (reader.status == AVAssetWriterStatusCompleted) 
        {
            [self endProcessing];
        }
    }
}

- (void)readNextAudioSampleFromOutput:(AVAssetReaderTrackOutput *)readerAudioTrackOutput;
{
    if (audioEncodingIsFinished)
    {
        return;
    }

    CMSampleBufferRef audioSampleBufferRef = [readerAudioTrackOutput copyNextSampleBuffer];
    
    if (audioSampleBufferRef) 
    {
        runSynchronouslyOnVideoProcessingQueue(^{
            [self.audioEncodingTarget processAudioBuffer:audioSampleBufferRef];
            
            CMSampleBufferInvalidate(audioSampleBufferRef);
            CFRelease(audioSampleBufferRef);
        });
    }
    else
    {
        audioEncodingIsFinished = YES;
    }
}

- (void)processMovieFrame:(CMSampleBufferRef)movieSampleBuffer; 
{
    CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(movieSampleBuffer);
    CVImageBufferRef movieFrame = CMSampleBufferGetImageBuffer(movieSampleBuffer);

    int bufferHeight = CVPixelBufferGetHeight(movieFrame);
    int bufferWidth = CVPixelBufferGetWidth(movieFrame);

    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        CVPixelBufferLockBaseAddress(movieFrame, 0);
        
        [GPUImageOpenGLESContext useImageProcessingContext];
        CVOpenGLESTextureRef texture = NULL;
        CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, movieFrame, NULL, GL_TEXTURE_2D, GL_RGBA, bufferWidth, bufferHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &texture);
        
        if (!texture || err) {
            NSLog(@"Movie CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);  
            return;
        }
        
        outputTexture = CVOpenGLESTextureGetName(texture);
        //        glBindTexture(CVOpenGLESTextureGetTarget(texture), outputTexture);
        glBindTexture(GL_TEXTURE_2D, outputTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        for (id<GPUImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger targetTextureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:targetTextureIndex];
            [currentTarget setInputTexture:outputTexture atIndex:targetTextureIndex];
            
            [currentTarget newFrameReadyAtTime:currentSampleTime atIndex:targetTextureIndex];
        }
        
        CVPixelBufferUnlockBaseAddress(movieFrame, 0);
        
        // Flush the CVOpenGLESTexture cache and release the texture
        CVOpenGLESTextureCacheFlush(coreVideoTextureCache, 0);
        CFRelease(texture);
        outputTexture = 0;        
    }
    else
    {
        // Upload to texture
        CVPixelBufferLockBaseAddress(movieFrame, 0);
        
        glBindTexture(GL_TEXTURE_2D, outputTexture);
        // Using BGRA extension to pull in video frame data directly
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(movieFrame));
        
        CGSize currentSize = CGSizeMake(bufferWidth, bufferHeight);
        for (id<GPUImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger targetTextureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];

            [currentTarget setInputSize:currentSize atIndex:targetTextureIndex];
            [currentTarget newFrameReadyAtTime:currentSampleTime atIndex:targetTextureIndex];
        }
        CVPixelBufferUnlockBaseAddress(movieFrame, 0);
    }
    
    if (_runBenchmark)
    {
        CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
        NSLog(@"Current frame time : %f ms", 1000.0 * currentFrameTime);
    }
}

- (void)endProcessing;
{
    for (id<GPUImageInput> currentTarget in targets)
    {
        [currentTarget endProcessing];
    }
    
    if (synchronizedMovieWriter != nil)
    {
        [synchronizedMovieWriter setVideoInputReadyCallback:^{}];
        [synchronizedMovieWriter setAudioInputReadyCallback:^{}];
    }
}

@end

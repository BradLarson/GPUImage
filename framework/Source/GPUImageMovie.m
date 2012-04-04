#import "GPUImageMovie.h"
#import "GPUImageMovieWriter.h"

@implementation GPUImageMovie

@synthesize url = _url;
@synthesize runBenchmark = _runBenchmark;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithURL:(NSURL *)url;
{
    if (!(self = [super init])) 
    {
        return nil;
    }
    
    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        [GPUImageOpenGLESContext useImageProcessingContext];
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &coreVideoTextureCache);
        if (err) 
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d");
        }
        
        // Need to remove the initially created texture
        [self deleteOutputTexture];
    }

    self.url = url;
    
    return self;
}

#pragma mark -
#pragma mark Movie processing

- (void)startProcessing;
{
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:self.url options:inputOptions];
    
    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
        NSError *error = nil;
        AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
        if (!tracksStatus == AVKeyValueStatusLoaded) 
        {
            return;
        }
        AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:inputAsset error:&error];
        
        NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
        [outputSettings setObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]  forKey: (NSString*)kCVPixelBufferPixelFormatTypeKey];
        // Maybe set alwaysCopiesSampleData to NO on iOS 5.0 for faster video decoding
        AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
        [reader addOutput:readerVideoTrackOutput];
        
        NSArray *audioTracks = [inputAsset tracksWithMediaType:AVMediaTypeAudio];
        BOOL shouldRecordAudioTrack = (([audioTracks count] > 0) && (self.audioEncodingTarget != nil) );
        AVAssetReaderTrackOutput *readerAudioTrackOutput = nil;

        if (shouldRecordAudioTrack)
        {            
            // This might need to be extended to handle movies with more than one audio track
            AVAssetTrack* audioTrack = [audioTracks objectAtIndex:0];
            readerAudioTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
            [reader addOutput:readerAudioTrackOutput];
        }

        if ([reader startReading] == NO) 
        {
            NSLog(@"Error reading from file at URL: %@", self.url);
            return;
        }

        while (reader.status == AVAssetReaderStatusReading) 
        {
            CMSampleBufferRef sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
            if (sampleBufferRef) 
            {
                runOnMainQueueWithoutDeadlocking(^{
                    [self processMovieFrame:sampleBufferRef]; 
                });
                
                CMSampleBufferInvalidate(sampleBufferRef);
                CFRelease(sampleBufferRef);
            }
            
            if (shouldRecordAudioTrack)
            {
                CMSampleBufferRef audioSampleBufferRef = [readerAudioTrackOutput copyNextSampleBuffer];

                if (audioSampleBufferRef) 
                {
//                    runOnMainQueueWithoutDeadlocking(^{
                        [self.audioEncodingTarget processAudioBuffer:audioSampleBufferRef]; 
//                    });
                    
                    CMSampleBufferInvalidate(audioSampleBufferRef);
                    CFRelease(audioSampleBufferRef);
                }
                else
                {
//                    NSLog(@"Ran out of audio frames");
                    shouldRecordAudioTrack = NO;
                }
            }
        }
        
        if (reader.status == AVAssetWriterStatusCompleted) {
            [self endProcessing];
        }
    }];
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
            NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);  
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
            [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight)];
            
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            [currentTarget setInputTexture:outputTexture atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
            
            [currentTarget newFrameReadyAtTime:currentSampleTime];
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
            [currentTarget setInputSize:currentSize];
            [currentTarget newFrameReadyAtTime:currentSampleTime];
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
}

@end

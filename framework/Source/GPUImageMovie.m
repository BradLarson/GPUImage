#import "GPUImageMovie.h"

@implementation GPUImageMovie

@synthesize url = _url;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithURL:(NSURL *)url;
{
    if (!(self = [super init])) 
    {
        return nil;
    }
    
    self.url = url;
    
    return self;
}

#pragma mark -
#pragma mark Movie processing

- (void)startProcessing;
{
    // AVURLAsset to read input movie (i.e. mov recorded to local storage)
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:self.url options:inputOptions];
    
    // Load the input asset tracks information
    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
        NSError *error = nil;
        // Check status of "tracks", make sure they were loaded    
        AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
        if (!tracksStatus == AVKeyValueStatusLoaded) {
            // failed to load
            return;
        }
        /* Read video samples from input asset video track */
        AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:inputAsset error:&error];
        
        NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
        [outputSettings setObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]  forKey: (NSString*)kCVPixelBufferPixelFormatTypeKey];
        AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
        
        // Assign the tracks to the reader and start to read
        [reader addOutput:readerVideoTrackOutput];
        if ([reader startReading] == NO) {
            // Handle error
            NSLog(@"Error reading");
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

    // Upload to texture
    CVPixelBufferLockBaseAddress(movieFrame, 0);
    int bufferHeight = CVPixelBufferGetHeight(movieFrame);
    int bufferWidth = CVPixelBufferGetWidth(movieFrame);
    
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

- (void)endProcessing;
{
    for (id<GPUImageInput> currentTarget in targets)
    {
        [currentTarget endProcessing];
    }
}

@end

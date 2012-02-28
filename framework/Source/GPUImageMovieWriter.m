#import "GPUImageMovieWriter.h"

@interface GPUImageMovieWriter ()
{
    GLuint inputTextureForMovieRendering;
    
    GLubyte *frameData;
    
    NSDate *startTime;
}

// Movie recording
- (void)initializeMovie;

@end

@implementation GPUImageMovieWriter

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithMovieURL:(NSURL *)newMovieURL;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    movieURL = newMovieURL;
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
    videoSize = CGSizeMake(480.0, 640.0);
    frameData = (GLubyte *) calloc(videoSize.width * videoSize.height * 4, sizeof(GLubyte));

    NSError *error = nil;
    assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
    }
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:videoSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:videoSize.height], AVVideoHeightKey, nil];
    assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    //writerInput.expectsMediaDataInRealTime = NO;
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    
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
#pragma mark GPUImageInput protocol

- (void)newFrameReady;
{
    glReadPixels(0, 0, videoSize.width, videoSize.height, GL_RGBA, GL_UNSIGNED_BYTE, frameData);
    CVPixelBufferRef pixel_buffer = NULL;
    CVPixelBufferCreateWithBytes (NULL, videoSize.width, videoSize.height, kCVPixelFormatType_32BGRA, frameData, 4 * videoSize.width, NULL, 0, NULL, &pixel_buffer);
    
    CMTime currentTime = CMTimeMakeWithSeconds([[NSDate date] timeIntervalSinceDate:startTime],30);
    
    if(![assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:currentTime]) 
    {
        NSLog(@"FAIL");
    } 
    else 
    {
//        NSLog(@"Success:%d", currentFrame);
//        currentTime = CMTimeAdd(currentTime, frameLength);
    }
    
    CVPixelBufferRelease(pixel_buffer);
    
//    currentFrame++;
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

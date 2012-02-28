#import "GPUImageMovieWriter.h"

@interface GPUImageMovieWriter ()
{
    GLuint inputTextureForMovieRendering;
}
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
    
    return self;
}


#pragma mark -
#pragma mark Movie recording

- (void)initializeMovie;
{
    videoSize = CGSizeMake(480.0, 640.0);
    
    NSError *error = nil;
    assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:videoSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:videoSize.height], AVVideoHeightKey, nil];
    assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    //writerInput.expectsMediaDataInRealTime = NO;
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    
    assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    [assetWriter addInput:assetWriterVideoInput];
    
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReady;
{
//    GLuint *buffer = (GLuint *) malloc(myDataLength);
//    glReadPixels(0, 0, esize.width, esize.height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
//    CVPixelBufferRef pixel_buffer = NULL;
//    CVPixelBufferCreateWithBytes (NULL, esize.width, esize.height, kCVPixelFormatType_32BGRA, buffer, 4 * esize.width, NULL, 0, NULL, &pixel_buffer);
//    
//    /* DON'T FREE THIS BEFORE USING pixel_buffer! */ 
//    //free(buffer);
//    
//    if(![adaptor appendPixelBuffer:pixel_buffer withPresentationTime:currentTime]) {
//        NSLog(@"FAIL");
//    } else {
//        NSLog(@"Success:%d", currentFrame);
//        currentTime = CMTimeAdd(currentTime, frameLength);
//    }
//    
//    free(buffer);
//    CVPixelBufferRelease(pixel_buffer);
//    
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

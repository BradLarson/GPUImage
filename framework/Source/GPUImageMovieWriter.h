#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImageOpenGLESContext.h"

@interface GPUImageMovieWriter : NSObject <GPUImageInput>
{
    CMVideoDimensions videoDimensions;
	CMVideoCodecType videoType;

    NSURL *movieURL;
	AVAssetWriter *assetWriter;
//	AVAssetWriterInput *assetWriterAudioIn;
	AVAssetWriterInput *assetWriterVideoInput;
    AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferInput;
	dispatch_queue_t movieWritingQueue;
    
    CGSize videoSize;
}

// Initialization and teardown
- (id)initWithMovieURL:(NSURL *)newMovieURL;

// Movie recording
- (void)initializeMovie;

@end

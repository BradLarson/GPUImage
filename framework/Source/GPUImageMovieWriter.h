#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImageOpenGLESContext.h"

@protocol GPUImageMovieWriterDelegate <NSObject>

@optional
-(void)Completed;
-(void)Failed:(NSError*)error;

@end

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

@property (nonatomic, copy) void(^CompletionBlock)(void);
@property (nonatomic, copy) void(^FailureBlock)(NSError*);
@property (nonatomic, assign) id<GPUImageMovieWriterDelegate> delegate;

// Initialization and teardown
- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize;

// Movie recording
- (void)startRecording;
- (void)finishRecording;

@end

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
	AVAssetWriterInput *assetWriterAudioInput;
	AVAssetWriterInput *assetWriterVideoInput;
    AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferInput;
	dispatch_queue_t movieWritingQueue;
    
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
    CVPixelBufferRef renderTarget;

    CGSize videoSize;
}

@property (readwrite, nonatomic) BOOL hasAudioTrack;
@property (readwrite, nonatomic) BOOL shouldPassthroughAudio;
@property (nonatomic, copy) void(^CompletionBlock)(void);
@property (nonatomic, copy) void(^FailureBlock)(NSError*);
@property (nonatomic, assign) id<GPUImageMovieWriterDelegate> delegate;
@property (readwrite, nonatomic) BOOL encodingLiveVideo;
@property (nonatomic, copy) void(^videoInputReadyCallback)(void);
@property (nonatomic, copy) void(^audioInputReadyCallback)(void);

// Initialization and teardown
- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize;

// Movie recording
- (void)startRecording;
- (void)finishRecording;
- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer;
- (void)enableSynchronizationCallbacks;

@end

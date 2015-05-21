#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImageContext.h"
#import "GPUImageOutput.h"

/** Protocol for getting Movie played callback.
 */
@protocol GPUImageMovieDelegate <NSObject>

- (void)didCompletePlayingMovie;
@end

/** Source object for filtering movies
 */
@interface GPUImageMovie : GPUImageOutput

@property (readwrite, retain) AVAsset *asset;
@property (readwrite, retain) AVPlayerItem *playerItem;
@property(readwrite, retain) NSURL *url;

/** This enables the benchmarking mode, which logs out instantaneous and average frame times to the console
 */
@property(readwrite, nonatomic) BOOL runBenchmark;

/** This determines whether to play back a movie as fast as the frames can be processed, or if the original speed of the movie should be respected. Defaults to NO.
 */
@property(readwrite, nonatomic) BOOL playAtActualSpeed;

/** This determines whether the video should repeat (loop) at the end and restart from the beginning. Defaults to NO.
 */
@property(readwrite, nonatomic) BOOL shouldRepeat;

/** This specifies the progress of the process on a scale from 0 to 1.0. A value of 0 means the process has not yet begun, A value of 1.0 means the conversaion is complete.
    This property is not key-value observable.
 */
@property(readonly, nonatomic) float progress;

/** This is used to send the delete Movie did complete playing alert
 */
@property (readwrite, nonatomic, assign) id <GPUImageMovieDelegate>delegate;

@property (readonly, nonatomic) AVAssetReader *assetReader;
@property (readonly, nonatomic) BOOL audioEncodingIsFinished;
@property (readonly, nonatomic) BOOL videoEncodingIsFinished;
@property (readwrite, nonatomic) BOOL shouldUseDisplayLinkTiming;

/// @name Initialization and teardown
- (id)initWithAsset:(AVAsset *)asset;
- (id)initWithPlayerItem:(AVPlayerItem *)playerItem;
- (id)initWithURL:(NSURL *)url;
- (void)yuvConversionSetup;

/// @name Movie processing
- (void)enableSynchronizedEncodingUsingMovieWriter:(GPUImageMovieWriter *)movieWriter;
- (BOOL)readNextVideoFrameFromOutput:(AVAssetReaderOutput *)readerVideoTrackOutput;
- (BOOL)readNextAudioSampleFromOutput:(AVAssetReaderOutput *)readerAudioTrackOutput;
- (void)startProcessingWithDisplayLinkTiming:(BOOL)useDisplayLink;
- (void)endProcessing;
- (void)cancelProcessing;
- (void)processMovieFrame:(CMSampleBufferRef)movieSampleBuffer; 
- (void)outputFrameAtTime:(CMTime)time;

@end

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageOutput.h"

/** Source object for filtering movies
 */
@interface GPUImageMovie : GPUImageOutput

@property(readwrite, retain) NSURL *url;

/** This enables the benchmarking mode, which logs out instantaneous and average frame times to the console
 */
@property(readwrite, nonatomic) BOOL runBenchmark;

/// @name Initialization and teardown
- (id)initWithURL:(NSURL *)url;

/// @name Movie processing
- (void)enableSynchronizedEncodingUsingMovieWriter:(GPUImageMovieWriter *)movieWriter;
- (void)readNextVideoFrameFromOutput:(AVAssetReaderTrackOutput *)readerVideoTrackOutput;
- (void)readNextAudioSampleFromOutput:(AVAssetReaderTrackOutput *)readerAudioTrackOutput;
- (void)startProcessing;
- (void)endProcessing;
- (void)processMovieFrame:(CMSampleBufferRef)movieSampleBuffer; 

@end

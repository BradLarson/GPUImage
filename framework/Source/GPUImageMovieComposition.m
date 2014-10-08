//
//  GPUImageMovieComposition.m
//  Givit
//
//  Created by Sean Meiners on 2013/01/25.
//
//

#import "GPUImageMovieComposition.h"
#import "GPUImageMovieWriter.h"

@implementation GPUImageMovieComposition

@synthesize compositon = _compositon;
@synthesize videoComposition = _videoComposition;
@synthesize audioMix = _audioMix;

- (id)initWithComposition:(AVComposition*)compositon
      andVideoComposition:(AVVideoComposition*)videoComposition
              andAudioMix:(AVAudioMix*)audioMix {
    if (!(self = [super init]))
    {
        return nil;
    }

    [self yuvConversionSetup];

    self.compositon = compositon;
    self.videoComposition = videoComposition;
    self.audioMix = audioMix;

    return self;
}

- (AVAssetReader*)createAssetReader
 {
    //NSLog(@"creating reader from composition: %@, video: %@, audio: %@ with duration: %@", _compositon, _videoComposition, _audioMix, CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, _compositon.duration)));

    NSError *error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:self.compositon error:&error];

    NSDictionary *outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
    AVAssetReaderVideoCompositionOutput *readerVideoOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:[_compositon tracksWithMediaType:AVMediaTypeVideo]
                                                                                                                                     videoSettings:outputSettings];
#if ! TARGET_IPHONE_SIMULATOR
    if( [_videoComposition isKindOfClass:[AVMutableVideoComposition class]] )
        [(AVMutableVideoComposition*)_videoComposition setRenderScale:1.0];
#endif
    readerVideoOutput.videoComposition = self.videoComposition;
    readerVideoOutput.alwaysCopiesSampleData = NO;
    [assetReader addOutput:readerVideoOutput];

    NSArray *audioTracks = [_compositon tracksWithMediaType:AVMediaTypeAudio];
    BOOL shouldRecordAudioTrack = (([audioTracks count] > 0) && (self.audioEncodingTarget != nil) );
    AVAssetReaderAudioMixOutput *readerAudioOutput = nil;

    if (shouldRecordAudioTrack)
    {
        [self.audioEncodingTarget setShouldInvalidateAudioSampleWhenDone:YES];
        
        readerAudioOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:nil];
        readerAudioOutput.audioMix = self.audioMix;
        readerAudioOutput.alwaysCopiesSampleData = NO;
        [assetReader addOutput:readerAudioOutput];
    }

    return assetReader;
}

@end

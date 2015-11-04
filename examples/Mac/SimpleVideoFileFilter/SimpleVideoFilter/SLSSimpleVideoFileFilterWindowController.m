#import "SLSSimpleVideoFileFilterWindowController.h"
#import <GPUImage/GPUImage.h>

@interface SLSSimpleVideoFileFilterWindowController ()
{
    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
    NSTimer * timer;
}

@property (weak) IBOutlet GPUImageView *videoView;
@property (weak) IBOutlet NSTextField *progressLabel;

@property (weak) IBOutlet NSView *containerView;
@property (weak) IBOutlet NSButton *urlButton;
@property (weak) IBOutlet NSButton *avPlayerItemButton;

@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation SLSSimpleVideoFileFilterWindowController


- (void)windowDidLoad {
    [super windowDidLoad];

    self.containerView.hidden = YES;

}

- (IBAction)gpuImageMovieWithURLButtonAction:(id)sender {
    [self runProcessingWithAVPlayerItem:NO];
    [self showProcessingUI];
}

- (IBAction)gpuImageMovieWithAvplayeritemButtonAction:(id)sender {
    [self runProcessingWithAVPlayerItem:YES];
    [self showProcessingUI];
}

- (void)showProcessingUI {
    self.containerView.hidden = NO;
    self.urlButton.hidden = YES;
    self.avPlayerItemButton.hidden = YES;
}

- (void)runProcessingWithAVPlayerItem:(BOOL)withAVPlayerItem {
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"sample_iPod" withExtension:@"m4v"];
    
    self.playerItem = [[AVPlayerItem alloc] initWithURL:sampleURL];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    //movieFile = [[GPUImageMovie alloc] initWithURL:sampleURL];
    movieFile = [[GPUImageMovie alloc] initWithPlayerItem:self.playerItem];
    movieFile.runBenchmark = YES;
    movieFile.playAtActualSpeed = NO;
    filter = [[GPUImagePixellateFilter alloc] init];
    //    filter = [[GPUImageUnsharpMaskFilter alloc] init];
    
    [movieFile addTarget:filter];
    
    // Only rotate the video for display, leave orientation the same for recording
    GPUImageView *filterView = (GPUImageView *)self.videoView;
    [filter addTarget:filterView];
    
    // In addition to displaying to the screen, write out a processed version of the movie to disk
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
    [filter addTarget:movieWriter];
    
    // Configure this for video from the movie file, where we want to preserve all video frames and audio samples
    movieWriter.shouldPassthroughAudio = YES;
    movieFile.audioEncodingTarget = movieWriter;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    [movieWriter startRecording];
    [movieFile startProcessing];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.3f
                                             target:self
                                           selector:@selector(retrievingProgress)
                                           userInfo:nil
                                            repeats:YES];
    
    [movieWriter setCompletionBlock:^{
        [filter removeTarget:movieWriter];
        [movieWriter finishRecording];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [timer invalidate];
            self.progressLabel.stringValue = @"100%";
        });
    }];
    
    [self.player play];
}

- (void)retrievingProgress
{
    self.progressLabel.stringValue = [NSString stringWithFormat:@"%d%%", (int)(movieFile.progress * 100)];
}

- (IBAction)updatePixelWidth:(id)sender
{
    //    [(GPUImageUnsharpMaskFilter *)filter setIntensity:[(UISlider *)sender value]];
    [(GPUImagePixellateFilter *)filter setFractionalWidthOfAPixel:[(NSSlider *)sender floatValue]];
}


@end

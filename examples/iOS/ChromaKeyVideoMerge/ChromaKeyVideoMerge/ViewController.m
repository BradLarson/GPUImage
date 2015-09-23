#import "ViewController.h"

#import <GPUImageView.h>
#import <GPUImageMovie.h>
#import <GPUImageChromaKeyBlendFilter.h>
#import <GPUImageMovieWriter.h>
#import <THImageMovie.h>
#import <THImageMovieWriter.h>

#import <AssetsLibrary/ALAsset.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <AssetsLibrary/ALAssetRepresentation.h>

@interface ViewController ()

@property (nonatomic, retain) GPUImageMovie *gpuMovieFX;
@property (nonatomic, retain) GPUImageMovie *gpuMovieA;
@property (nonatomic, retain) GPUImageMovieWriter *movieWriter;
@property (nonatomic, retain) GPUImageChromaKeyBlendFilter *filter;
@property (nonatomic, retain) ALAssetsLibrary *library;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *spinner;


@property (nonatomic, retain) THImageMovie *thMovieFX;
@property (nonatomic, retain) THImageMovie *thMovieA;
@property (nonatomic, retain) THImageMovieWriter *thMovieWriter;

@end    

@implementation ViewController {

    NSURL *fxURL;
    NSURL *rawVideoURL;
};


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];


    fxURL = [[NSBundle mainBundle] URLForResource:@"FXSample" withExtension:@"mov"];
    rawVideoURL = [[NSBundle mainBundle] URLForResource:@"Record" withExtension:@"mov"];


    [self printDuration:fxURL];
    [self printDuration:rawVideoURL];


}

- (void)printDuration:(NSURL *)url{
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:url options:inputOptions];

    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
        NSLog(@"movie: %@ duration: %.2f", url.lastPathComponent, CMTimeGetSeconds(inputAsset.duration));
    }];

}

- (IBAction)onGPUMerge {



    self.gpuMovieA = [[GPUImageMovie alloc] initWithURL:rawVideoURL];
    self.gpuMovieFX = [[GPUImageMovie alloc] initWithURL:fxURL];


    self.filter = [[GPUImageChromaKeyBlendFilter alloc] init];
    [self.filter forceProcessingAtSize:CGSizeMake(640, 640)];

    [self.gpuMovieFX addTarget:self.filter];
    [self.gpuMovieA addTarget:self.filter];


    //setup writer
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/gpu_output.mov"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *outputURL = [NSURL fileURLWithPath:pathToMovie];
    self.movieWriter =  [[GPUImageMovieWriter alloc] initWithMovieURL:outputURL size:CGSizeMake(640.0, 640.0)];
    [self.filter addTarget:self.movieWriter];

    self.movieWriter.shouldPassthroughAudio = YES;
    self.gpuMovieA.audioEncodingTarget = self.movieWriter;
//add this line otherwise it will cause "Had to drop an audio frame" which cozes the saved video lose some sounds
    [self.gpuMovieA enableSynchronizedEncodingUsingMovieWriter:self.movieWriter];


    self.startDate = [NSDate date];

    [self.movieWriter startRecording];
    [self.gpuMovieA startProcessing];
    [self.gpuMovieFX startProcessing];

    self.spinner.hidden = NO;
     __weak typeof(self) weakSelf = self;

    [self.movieWriter setCompletionBlock:^{
        weakSelf.gpuMovieA.audioEncodingTarget = nil;
        [weakSelf.gpuMovieFX endProcessing];
        [weakSelf.gpuMovieA endProcessing];
        [weakSelf.movieWriter finishRecordingWithCompletionHandler:^{
            NSLog(@"movie writing done");
            dispatch_async(dispatch_get_main_queue(), ^{
                // [SVProgressHUD showErrorWithStatus:@"failed"];
                weakSelf.spinner.hidden = YES;
            });
            [weakSelf writeToAlbum:outputURL];
            [weakSelf printDuration:outputURL];
        }];
    }];



}
- (IBAction)onTHMerge:(id)sender {

    self.thMovieA = [[THImageMovie alloc] initWithURL:rawVideoURL];
    self.thMovieFX = [[THImageMovie alloc] initWithURL:fxURL];


    self.filter = [[GPUImageChromaKeyBlendFilter alloc] init];
    [self.filter forceProcessingAtSize:CGSizeMake(640, 640)];

    [self.thMovieFX addTarget:self.filter];
    [self.thMovieA addTarget:self.filter];


    NSArray *thMovies = @[self.thMovieA, self.thMovieFX];

    //setup writer
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/th_output.mov"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *outputURL = [NSURL fileURLWithPath:pathToMovie];
    self.thMovieWriter =  [[THImageMovieWriter alloc] initWithMovieURL:outputURL size:CGSizeMake(640.0, 640.0) movies:thMovies];
    [self.filter addTarget:self.thMovieWriter];


    self.startDate = [NSDate date];


    [self.thMovieA startProcessing];
    [self.thMovieFX startProcessing];
    [self.thMovieWriter startRecording];

    self.spinner.hidden = NO;
    __weak typeof(self) weakSelf = self;

    [self.thMovieWriter setCompletionBlock:^{
        [weakSelf.thMovieFX endProcessing];
        [weakSelf.thMovieA endProcessing];


        NSLog(@"movie writing done");
        dispatch_async(dispatch_get_main_queue(), ^{
            // [SVProgressHUD showErrorWithStatus:@"failed"];
            weakSelf.spinner.hidden = YES;
        });
        [weakSelf writeToAlbum:outputURL];
        [weakSelf printDuration:outputURL];


    }];


}


- (void)writeToAlbum:(NSURL *)outputFileURL{
    self.library = [[ALAssetsLibrary alloc] init];
  
        [self.library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
                                     completionBlock:^(NSURL *assetURL, NSError *error)
                                     {
                                         if (error)
                                         {
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                // [SVProgressHUD showErrorWithStatus:@"failed"];
                                             });
                                             NSLog(@"fail to saved: %@", error);
                                         }else{
                                             NSLog(@"saved");
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                // [SVProgressHUD showSuccessWithStatus:@"saved"];
                                             });
                                         }
                                     }];
    
}


- (void)viewDidUnload
{
    [self setSpinner:nil];
    [self setGpuTimeLabel:nil];
    [self setThTimeLabel:nil];
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; // Support all orientations.
}

- (void)dealloc {
    [_library release];
    [_spinner release];
    [_gpuTimeLabel release];
    [_thTimeLabel release];
    [super dealloc];
}

@end

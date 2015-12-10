#import "SimpleVideoFilterViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation SimpleVideoFilterViewController {
    NSURL *_movieURL;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    //    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
    
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    //    filter = [[GPUImageSepiaFilter alloc] init];
    
    //    filter = [[GPUImageTiltShiftFilter alloc] init];
    //    [(GPUImageTiltShiftFilter *)filter setTopFocusLevel:0.65];
    //    [(GPUImageTiltShiftFilter *)filter setBottomFocusLevel:0.85];
    //    [(GPUImageTiltShiftFilter *)filter setBlurSize:1.5];
    //    [(GPUImageTiltShiftFilter *)filter setFocusFallOffRate:0.2];
    
    //    filter = [[GPUImageSketchFilter alloc] init];
    //    filter = [[GPUImageColorInvertFilter alloc] init];
    filter = [[GPUImageSmoothToonFilter alloc] init];
    //    GPUImageRotationFilter *rotationFilter = [[GPUImageRotationFilter alloc] initWithRotation:kGPUImageRotateRightFlipVertical];
    
    [videoCamera addTarget:filter];
    GPUImageView *filterView = (GPUImageView *)self.view;
    //    filterView.fillMode = kGPUImageFillModeStretch;
    //    filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
    // Record a movie for 10 s and store it in /Documents, visible via iTunes file sharing
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    _movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:_movieURL size:CGSizeMake(480.0, 640.0)];
    movieWriter.encodingLiveVideo = YES;
    //    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
    //    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720.0, 1280.0)];
    //    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(1080.0, 1920.0)];
    [filter addTarget:movieWriter];
    [filter addTarget:filterView];
    
    videoCamera.audioEncodingTarget = movieWriter;
    
    
    //        NSError *error = nil;
    //        if (![videoCamera.inputCamera lockForConfiguration:&error])
    //        {
    //            NSLog(@"Error locking for configuration: %@", error);
    //        }
    //        [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
    //        [videoCamera.inputCamera unlockForConfiguration];
    
    
    //            [videoCamera.inputCamera lockForConfiguration:nil];
    //            [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
    //            [videoCamera.inputCamera unlockForConfiguration];
    [self addButtons];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [videoCamera startCameraCapture];
}

- (void)viewWillDisappear:(BOOL)animated {
    [videoCamera stopCameraCapture];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Map UIDeviceOrientation to UIInterfaceOrientation.
    UIInterfaceOrientation orient = UIInterfaceOrientationPortrait;
    switch ([[UIDevice currentDevice] orientation])
    {
        case UIDeviceOrientationLandscapeLeft:
            orient = UIInterfaceOrientationLandscapeLeft;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            orient = UIInterfaceOrientationLandscapeRight;
            break;
            
        case UIDeviceOrientationPortrait:
            orient = UIInterfaceOrientationPortrait;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            orient = UIInterfaceOrientationPortraitUpsideDown;
            break;
            
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown:
            // When in doubt, stay the same.
            orient = fromInterfaceOrientation;
            break;
    }
    videoCamera.outputImageOrientation = orient;
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; // Support all orientations.
}

#pragma mark - event response

- (void)runButtonPressed:(UIButton *)button {
    button.selected = !button.selected;
    if (button.selected) {
        NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:pathToMovie]) {
            [[NSFileManager defaultManager] removeItemAtPath:pathToMovie error:nil];
        }
        [movieWriter startRecording];
        [button setTitle:@"Finish" forState:UIControlStateNormal];
    } else {
        [button setTitle:@"Run" forState:UIControlStateNormal];
        
        NSLog(@"Movie completed");
    }
}

- (void)playButtonPressed:(UIButton *)button {
    [self stopCapture];
    [videoCamera stopCameraCapture];
    MPMoviePlayerController *movie = [[MPMoviePlayerController alloc] initWithContentURL:_movieURL];
    [movie setControlStyle:MPMovieControlStyleFullscreen];
    [movie.view setBackgroundColor:[UIColor clearColor]];
    [movie.view setFrame:self.view.bounds];
    [self.view addSubview:movie.view];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myMovieFinishedCallback:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:movie];
    [movie play];
    
}

- (IBAction)updateSliderValue:(id)sender
{
    [(GPUImageSepiaFilter *)filter setIntensity:[(UISlider *)sender value]];
}

- (void)addButtons {
    UIButton *runButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 30, 60, 60)];
    [runButton setTitle:@"Run" forState:UIControlStateNormal];
    [runButton addTarget:self action:@selector(runButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:runButton];
    
    UIButton *playButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 30, 60, 60)];
    [playButton setTitle:@"Play" forState:UIControlStateNormal];
    [playButton addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playButton];
}

- (void)stopCapture {
    [filter removeTarget:movieWriter];
    videoCamera.audioEncodingTarget = nil;
    [movieWriter finishRecording];
}

-(void)myMovieFinishedCallback:(NSNotification*)notify
{
    //视频播放对象
    MPMoviePlayerController* theMovie = [notify object];
    //销毁播放通知
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:theMovie];
    [theMovie.view removeFromSuperview];
    [videoCamera startCameraCapture];
}

@end

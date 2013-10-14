#import "StartPauseExampleViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation StartPauseExampleViewController

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
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];
//    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
//    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720.0, 1280.0)];
//    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(1080.0, 1920.0)];
    
    [videoCamera addTarget:movieWriter];
    GPUImageView *filterView = (GPUImageView *)self.view;
    [videoCamera addTarget:filterView];
    
    [videoCamera startCameraCapture];
    
    videoCamera.audioEncodingTarget = movieWriter;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
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

- (IBAction)switchFilter:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    if (filter == nil) {
        filter = [[GPUImageSepiaFilter alloc] init];
    }
    
    GPUImageView *filterView = (GPUImageView *)self.view;
    
    if (sender.selected) {
        [videoCamera removeTarget:movieWriter];
        [videoCamera removeTarget:filterView];
        
        [videoCamera addTarget:filter];
        [filter addTarget:movieWriter];
        [filter addTarget:filterView];
    } else {
        [videoCamera removeTarget:filter];
        [filter removeAllTargets];
        
        [videoCamera addTarget:movieWriter];
        [videoCamera addTarget:filterView];
    }
}

- (IBAction)switchRecord:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected) {
        if (movieWriter.isPaused) {
            NSLog(@"Movie resumed");
            movieWriter.paused = NO;
        } else {
            NSLog(@"Movie started");
            [movieWriter startRecording];
        }
    } else {
        movieWriter.paused = YES;
        NSLog(@"Movie paused");
    }
}

- (IBAction)stopRecord:(UIButton *)sender
{
    [videoCamera removeTarget:movieWriter];
    [filter removeTarget:movieWriter];
    
    videoCamera.audioEncodingTarget = nil;
    [movieWriter finishRecording];
    NSLog(@"Movie completed");
    
    [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error == nil) {
            NSLog(@"Movie saved");
        } else {
            NSLog(@"Error %@", error);
        }
    }];
    
    self.view.userInteractionEnabled = NO;
}

- (IBAction)updateSliderValue:(id)sender
{
    [(GPUImageSepiaFilter *)filter setIntensity:[(UISlider *)sender value]];
}

@end

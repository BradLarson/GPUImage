#import "SimpleVideoFilterViewController.h"
#import <AssetsLibrary/ALAssetsLibrary.h>

@implementation SimpleVideoFilterViewController

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

    filter = [[GPUImageSepiaFilter alloc] init];
  
//    filter = [[GPUImageTiltShiftFilter alloc] init];
//    [(GPUImageTiltShiftFilter *)filter setTopFocusLevel:0.65];
//    [(GPUImageTiltShiftFilter *)filter setBottomFocusLevel:0.85];
//    [(GPUImageTiltShiftFilter *)filter setBlurSize:1.5];
//    [(GPUImageTiltShiftFilter *)filter setFocusFallOffRate:0.2];
    
//    filter = [[GPUImageSketchFilter alloc] init];
//    filter = [[GPUImageColorInvertFilter alloc] init];
//    filter = [[GPUImageSmoothToonFilter alloc] init];
//    GPUImageRotationFilter *rotationFilter = [[GPUImageRotationFilter alloc] initWithRotation:kGPUImageRotateRightFlipVertical];
    
    [videoCamera addTarget:filter];
    GPUImageView *filterView = (GPUImageView *)self.view;
//    filterView.fillMode = kGPUImageFillModeStretch;
//    filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
    // Record a movie for 10 s and store it in /Documents, visible via iTunes file sharing
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];
    movieWriter.encodingLiveVideo = YES;
//    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
//    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720.0, 1280.0)];
//    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(1080.0, 1920.0)];
    [filter addTarget:movieWriter];
    [filter addTarget:filterView];
    
    [videoCamera startCameraCapture];
    
    double delayToStartRecording = 0.5;
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToStartRecording * NSEC_PER_SEC);
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"Start recording");
        
        videoCamera.audioEncodingTarget = movieWriter;
        [movieWriter startRecording];

//        NSError *error = nil;
//        if (![videoCamera.inputCamera lockForConfiguration:&error])
//        {
//            NSLog(@"Error locking for configuration: %@", error);
//        }
//        [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
//        [videoCamera.inputCamera unlockForConfiguration];

        double delayInSeconds = 10.0;
        dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
            
            [movieWriter finishRecordingWithCompletionHandler:^{
                [filter removeTarget:movieWriter];
                videoCamera.audioEncodingTarget = nil;
                NSLog(@"Movie completed");
                
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:movieURL])
                {
                    [library writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error)
                     {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             
                             if (error) {
                                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                                                delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                 [alert show];
                             } else {
                                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                                                delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                 [alert show];
                             }
                         });
                     }];
                }
                
            }];
//            [videoCamera.inputCamera lockForConfiguration:nil];
//            [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
//            [videoCamera.inputCamera unlockForConfiguration];
        });
    });
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

- (IBAction)updateSliderValue:(id)sender
{
    [(GPUImageSepiaFilter *)filter setIntensity:[(UISlider *)sender value]];
}

@end

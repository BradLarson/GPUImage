#import "SLSSimpleVideoFilterWindowController.h"

@interface SLSSimpleVideoFilterWindowController ()

@end

@implementation SLSSimpleVideoFilterWindowController


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    // Instantiate video camera
    videoCamera = [[GPUImageAVCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraDevice:nil];
    videoCamera.runBenchmark = YES;
    
    // Create filter and add it to target
    filter = [[GPUImageSepiaFilter alloc] init];
    [videoCamera addTarget:filter];
    
    // Save video to desktop
    NSError *error = nil;
    
    NSURL *pathToDesktop = [[NSFileManager defaultManager] URLForDirectory:NSDesktopDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    NSURL *pathToMovieFile = [pathToDesktop URLByAppendingPathComponent:@"movie.mp4"];
    NSString *filePathString = [pathToMovieFile absoluteString];
    NSString *filePathSubstring = [filePathString substringFromIndex:7];
    unlink([filePathSubstring UTF8String]);
    
    // Instantiate movie writer and add targets
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:pathToMovieFile size:CGSizeMake(640.0, 480.0)];
    movieWriter.encodingLiveVideo = YES;
    
    self.videoView.fillMode = kGPUImageFillModePreserveAspectRatio;
    [filter addTarget:movieWriter];
    [filter addTarget:self.videoView];
    
    // Start capturing
    [videoCamera startCameraCapture];
    
    double delayToStartRecording = 0.5;
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToStartRecording * NSEC_PER_SEC);
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"Start recording");
        
        videoCamera.audioEncodingTarget = movieWriter;
        [movieWriter startRecording];
        
        double delayInSeconds = 10.0;
        dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
            
            [filter removeTarget:movieWriter];
            videoCamera.audioEncodingTarget = nil;
            [movieWriter finishRecording];
            NSLog(@"Movie completed");

        });
    });

}

@end

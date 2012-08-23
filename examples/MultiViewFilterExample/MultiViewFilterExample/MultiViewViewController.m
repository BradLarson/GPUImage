#import "MultiViewViewController.h"

@implementation MultiViewViewController

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

- (void)loadView
{    
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];	
	UIView *primaryView = [[UIView alloc] initWithFrame:mainScreenFrame];
    primaryView.backgroundColor = [UIColor blueColor];
	self.view = primaryView;

    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    CGFloat halfWidth = round(mainScreenFrame.size.width / 2.0);
    CGFloat halfHeight = round(mainScreenFrame.size.height / 2.0);    
    view1 = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, halfWidth, halfHeight)];
    view2 = [[GPUImageView alloc] initWithFrame:CGRectMake(halfWidth, 0.0, halfWidth, halfHeight)];
    view3 = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, halfHeight, halfWidth, halfHeight)];
    view4 = [[GPUImageView alloc] initWithFrame:CGRectMake(halfWidth, halfHeight, halfWidth, halfHeight)];
    [self.view addSubview:view1];
    [self.view addSubview:view2];
    [self.view addSubview:view3];
    [self.view addSubview:view4];
    
    GPUImageFilter *filter1 = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Shader1"];
    GPUImageFilter *filter2 = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Shader2"];
    GPUImageSepiaFilter *filter3 = [[GPUImageSepiaFilter alloc] init];

    // For thumbnails smaller than the input video size, we currently need to make them render at a smaller size.
    // This is to avoid wasting processing time on larger frames than will be displayed.
    // You'll need to use -forceProcessingAtSize: with a zero size to re-enable full frame processing of video.
    [filter1 forceProcessingAtSize:view2.sizeInPixels];
    [filter2 forceProcessingAtSize:view3.sizeInPixels];
    [filter3 forceProcessingAtSize:view4.sizeInPixels];

    [videoCamera addTarget:view1];
    [videoCamera addTarget:filter1];
    [filter1 addTarget:view2];
    [videoCamera addTarget:filter2];
    [filter2 addTarget:view3];
    [videoCamera addTarget:filter3];
    [filter3 addTarget:view4];

    [videoCamera startCameraCapture];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

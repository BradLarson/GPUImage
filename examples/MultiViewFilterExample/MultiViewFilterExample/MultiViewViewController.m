#import "MultiViewViewController.h"

@implementation MultiViewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{    
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];	
	UIView *primaryView = [[UIView alloc] initWithFrame:mainScreenFrame];
    primaryView.backgroundColor = [UIColor blueColor];
	self.view = primaryView;

    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];

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
    
    GPUImageRotationFilter *rotationFilter = [[GPUImageRotationFilter alloc] initWithRotation:kGPUImageRotateRight];
    GPUImageFilter *filter1 = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Shader1"];
    GPUImageFilter *filter2 = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Shader2"];
    GPUImageSepiaFilter *filter3 = [[GPUImageSepiaFilter alloc] init];
    
    [videoCamera addTarget:rotationFilter];
    
    [rotationFilter addTarget:view1];
    [rotationFilter addTarget:filter1];
    [filter1 addTarget:view2];
    [rotationFilter addTarget:filter2];
    [filter2 addTarget:view3];
    [rotationFilter addTarget:filter3];
    [filter3 addTarget:view4];
    
    [videoCamera startCameraCapture];
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

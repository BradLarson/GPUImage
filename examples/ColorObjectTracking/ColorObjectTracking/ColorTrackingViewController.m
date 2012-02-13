#import "ColorTrackingViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation ColorTrackingViewController

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
		
		[currentDefaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithFloat:0.89f], @"thresholdColorR", 
                                           [NSNumber numberWithFloat:0.78f], @"thresholdColorG", 
                                           [NSNumber numberWithFloat:0.0f], @"thresholdColorB", 
                                           [NSNumber numberWithFloat:0.7], @"thresholdSensitivity", 
										   nil]];
		
		thresholdColor[0] = [currentDefaults floatForKey:@"thresholdColorR"];
		thresholdColor[1] = [currentDefaults floatForKey:@"thresholdColorG"];
		thresholdColor[2] = [currentDefaults floatForKey:@"thresholdColorB"];
		displayMode = PASSTHROUGH_VIDEO;
		thresholdSensitivity = [currentDefaults floatForKey:@"thresholdSensitivity"];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)loadView 
{
	CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];	
	UIView *primaryView = [[UIView alloc] initWithFrame:mainScreenFrame];
    primaryView.backgroundColor = [UIColor blueColor];
	self.view = primaryView;

    [self configureVideoFiltering];
    [self configureToolbar];
    [self configureTrackingDot];
}

- (void)configureVideoFiltering;
{
	CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];	
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    filteredVideoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, mainScreenFrame.size.width, mainScreenFrame.size.height)];
    [self.view addSubview:filteredVideoView];
    
    thresholdFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Threshold"];
    [thresholdFilter setFloat:thresholdSensitivity forUniform:@"threshold"];    
    [thresholdFilter setFloatVec3:thresholdColor forUniform:@"inputColor"];
    positionFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"PositionColor"];
    [positionFilter setFloat:thresholdSensitivity forUniform:@"threshold"];
    [positionFilter setFloatVec3:thresholdColor forUniform:@"inputColor"];
    rotationFilter = [[GPUImageRotationFilter alloc] initWithRotation:kGPUImageRotateRight];
    
    // videoCamera -> thresholdFilter -> filteredVideoView
    [videoCamera addTarget:rotationFilter];
    [rotationFilter addTarget:filteredVideoView];
    
    [videoCamera startCameraCapture];
}

- (void)configureToolbar;
{
	UISegmentedControl *displayModeControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"Video", nil), NSLocalizedString(@"Threshold", nil), NSLocalizedString(@"Position", nil), NSLocalizedString(@"Track", nil), nil]];
	displayModeControl.segmentedControlStyle = UISegmentedControlStyleBar;
	displayModeControl.selectedSegmentIndex = 0;
	[displayModeControl addTarget:self action:@selector(handleSwitchOfDisplayMode:) forControlEvents:UIControlEventValueChanged];
	
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:displayModeControl];
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];	

	displayModeControl.frame = CGRectMake(0.0f, 10.0f, mainScreenFrame.size.width - 20.0f, 30.0f);
	
	NSArray *theToolbarItems = [NSArray arrayWithObjects:item, nil];
	
	UIToolbar *lowerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height - 44.0f, self.view.frame.size.width, 44.0f)];
	lowerToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	lowerToolbar.tintColor = [UIColor blackColor];
	
	[lowerToolbar setItems:theToolbarItems];
	
	[self.view addSubview:lowerToolbar];
}

- (void)configureTrackingDot;
{
	trackingDot = [[CALayer alloc] init];
	trackingDot.bounds = CGRectMake(0.0f, 0.0f, 40.0f, 40.0f);
	trackingDot.cornerRadius = 20.0f;
	trackingDot.backgroundColor = [[UIColor blueColor] CGColor];
	
	NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"position", nil];
	
	trackingDot.actions = newActions;
    
    //	[glView.layer addSublayer:trackingDot];
	trackingDot.position = CGPointMake(100.0f, 100.0f);
	trackingDot.opacity = 0.0f;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Display mode switching

- (void)handleSwitchOfDisplayMode:(id)sender;
{
    ColorTrackingDisplayMode newDisplayMode = [sender selectedSegmentIndex];
    
    if (newDisplayMode != displayMode)
    {
        switch (displayMode)
        {
            case SIMPLE_THRESHOLDING: [thresholdFilter removeTarget:filteredVideoView]; break;
            case POSITION_THRESHOLDING: [positionFilter removeTarget:filteredVideoView]; break;
            default: break;
        }
        if (displayMode == OBJECT_TRACKING)
        {
            trackingDot.opacity = 1.0f;
        }
        else
        {
            trackingDot.opacity = 0.0f;
        }
        
        displayMode = newDisplayMode;
        [rotationFilter removeAllTargets];

        
        switch(displayMode)
        {
            case PASSTHROUGH_VIDEO: 
            {
                [rotationFilter addTarget:filteredVideoView];
            }; break;
            case SIMPLE_THRESHOLDING: 
            {
                [rotationFilter addTarget:thresholdFilter];
                [thresholdFilter addTarget:filteredVideoView];
            }; break;
            case POSITION_THRESHOLDING: 
            {
                [rotationFilter addTarget:positionFilter];
                [positionFilter addTarget:filteredVideoView];
            }; break;
            case OBJECT_TRACKING: 
            {
                [rotationFilter addTarget:filteredVideoView];
                [rotationFilter addTarget:positionFilter];
            }; break;
        }
    }    
}

#pragma mark -
#pragma mark Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	currentTouchPoint = [[touches anyObject] locationInView:self.view];
	shouldReplaceThresholdColor = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	CGPoint movedPoint = [[touches anyObject] locationInView:self.view]; 
	CGFloat distanceMoved = sqrt( (movedPoint.x - currentTouchPoint.x) * (movedPoint.x - currentTouchPoint.x) + (movedPoint.y - currentTouchPoint.y) * (movedPoint.y - currentTouchPoint.y) );
    
	thresholdSensitivity = distanceMoved / 160.0f;
	[[NSUserDefaults standardUserDefaults] setFloat:thresholdSensitivity forKey:@"thresholdSensitivity"];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
}


@end

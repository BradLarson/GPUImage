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
    [super didReceiveMemoryWarning];
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
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    filteredVideoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, mainScreenFrame.size.width, mainScreenFrame.size.height)];
    [self.view addSubview:filteredVideoView];

    thresholdFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Threshold"];
    [thresholdFilter setFloat:thresholdSensitivity forUniform:@"threshold"];
    [thresholdFilter setFloatVec3:thresholdColor forUniform:@"inputColor"];
    positionFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"PositionColor"];
    [positionFilter setFloat:thresholdSensitivity forUniform:@"threshold"];
    [positionFilter setFloatVec3:thresholdColor forUniform:@"inputColor"];
    
//    CGSize videoPixelSize = filteredVideoView.bounds.size;
//    videoPixelSize.width *= [filteredVideoView contentScaleFactor];
//    videoPixelSize.height *= [filteredVideoView contentScaleFactor];
    
    CGSize videoPixelSize = CGSizeMake(480.0, 640.0);
    
    positionRawData = [[GPUImageRawData alloc] initWithImageSize:videoPixelSize];
    positionRawData.delegate = self;
    
    videoRawData = [[GPUImageRawData alloc] initWithImageSize:videoPixelSize];
    videoRawData.delegate = self;

    [videoCamera addTarget:filteredVideoView];
    [videoCamera addTarget:videoRawData];

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
    
	trackingDot.position = CGPointMake(100.0f, 100.0f);
	trackingDot.opacity = 0.0f;
    
    [self.view.layer addSublayer:trackingDot];
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
        displayMode = newDisplayMode;
        if (displayMode == OBJECT_TRACKING)
        {
            trackingDot.opacity = 1.0f;
        }
        else
        {
            trackingDot.opacity = 0.0f;
        }
        
        [videoCamera removeAllTargets];
        [positionFilter removeAllTargets];
        [thresholdFilter removeAllTargets];
        [videoCamera addTarget:videoRawData];
        
        switch(displayMode)
        {
            case PASSTHROUGH_VIDEO: 
            {
                [videoCamera addTarget:filteredVideoView];
            }; break;
            case SIMPLE_THRESHOLDING: 
            {
                [videoCamera addTarget:thresholdFilter];
                [thresholdFilter addTarget:filteredVideoView];
            }; break;
            case POSITION_THRESHOLDING: 
            {
                [videoCamera addTarget:positionFilter];
                [positionFilter addTarget:filteredVideoView];
            }; break;
            case OBJECT_TRACKING: 
            {
                [videoCamera addTarget:filteredVideoView];
                [videoCamera addTarget:positionFilter];
                [positionFilter addTarget:positionRawData];
            }; break;
        }
    }    
}

#pragma mark -
#pragma mark Image processing

- (CGPoint)centroidFromTexture:(GLubyte *)pixels ofSize:(CGSize)textureSize;
{
	CGFloat currentXTotal = 0.0f, currentYTotal = 0.0f, currentPixelTotal = 0.0f;
	
    if ([GPUImageOpenGLESContext supportsFastTextureUpload]) 
    {
        for (NSUInteger currentPixel = 0; currentPixel < (textureSize.width * textureSize.height); currentPixel++)
        {
            currentXTotal += (CGFloat)pixels[(currentPixel * 4) + 2] / 255.0f;
            currentYTotal += (CGFloat)pixels[(currentPixel * 4) + 1] / 255.0f;
            currentPixelTotal += (CGFloat)pixels[(currentPixel * 4) + 3] / 255.0f;
        }
    }
    else
    {
        for (NSUInteger currentPixel = 0; currentPixel < (textureSize.width * textureSize.height); currentPixel++)
        {
            currentXTotal += (CGFloat)pixels[currentPixel * 4] / 255.0f;
            currentYTotal += (CGFloat)pixels[(currentPixel * 4) + 1] / 255.0f;
            currentPixelTotal += (CGFloat)pixels[(currentPixel * 4) + 3] / 255.0f;
        }
    }
	
	return CGPointMake(currentXTotal / currentPixelTotal, currentYTotal / currentPixelTotal);
}

#pragma mark -
#pragma mark GPUImageRawDataProcessor protocol

- (void)newImageFrameAvailableFromDataSource:(GPUImageRawData *)rawDataSource;
{
    if (rawDataSource == positionRawData)
    {
        GLubyte *bytesForPositionData = rawDataSource.rawBytesForImage;
        CGPoint currentTrackingLocation = [self centroidFromTexture:bytesForPositionData ofSize:[rawDataSource maximumOutputSize]];		
        CGSize currentViewSize = self.view.bounds.size;
		trackingDot.position = CGPointMake(currentTrackingLocation.x * currentViewSize.width, currentTrackingLocation.y * currentViewSize.height);
    }
    else
    {
        if (shouldReplaceThresholdColor)
        {
            CGSize currentViewSize = self.view.bounds.size;
            CGSize rawPixelsSize = [rawDataSource maximumOutputSize];
            
            
            CGPoint scaledTouchPoint;
            scaledTouchPoint.x = (currentTouchPoint.x / currentViewSize.width) * rawPixelsSize.width;
            scaledTouchPoint.y = (currentTouchPoint.y / currentViewSize.height) * rawPixelsSize.height;
            
            GPUByteColorVector colorAtTouchPoint = [rawDataSource colorAtLocation:scaledTouchPoint];
            
            thresholdColor[0] = (float)colorAtTouchPoint.red / 255.0;
            thresholdColor[1] = (float)colorAtTouchPoint.green / 255.0;
            thresholdColor[2] = (float)colorAtTouchPoint.blue / 255.0;

//            NSLog(@"Color at touch point: %d, %d, %d, %d", colorAtTouchPoint.red, colorAtTouchPoint.green, colorAtTouchPoint.blue, colorAtTouchPoint.alpha);

            [[NSUserDefaults standardUserDefaults] setFloat:thresholdColor[0] forKey:@"thresholdColorR"];
            [[NSUserDefaults standardUserDefaults] setFloat:thresholdColor[1] forKey:@"thresholdColorG"];
            [[NSUserDefaults standardUserDefaults] setFloat:thresholdColor[2] forKey:@"thresholdColorB"];
            
            [thresholdFilter setFloatVec3:thresholdColor forUniform:@"inputColor"];
            [positionFilter setFloatVec3:thresholdColor forUniform:@"inputColor"];

            shouldReplaceThresholdColor = NO;
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

    [thresholdFilter setFloat:thresholdSensitivity forUniform:@"threshold"];    
    [positionFilter setFloat:thresholdSensitivity forUniform:@"threshold"];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
}


@end

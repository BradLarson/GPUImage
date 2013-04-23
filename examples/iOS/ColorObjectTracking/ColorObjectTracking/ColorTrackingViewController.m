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
		
		thresholdColor.one = [currentDefaults floatForKey:@"thresholdColorR"];
		thresholdColor.two = [currentDefaults floatForKey:@"thresholdColorG"];
		thresholdColor.three = [currentDefaults floatForKey:@"thresholdColorB"];
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
    [thresholdFilter setFloat:thresholdSensitivity forUniformName:@"threshold"];
    [thresholdFilter setFloatVec3:thresholdColor forUniformName:@"inputColor"];
    positionFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"PositionColor"];
    [positionFilter setFloat:thresholdSensitivity forUniformName:@"threshold"];
    [positionFilter setFloatVec3:thresholdColor forUniformName:@"inputColor"];
    
//    CGSize videoPixelSize = filteredVideoView.bounds.size;
//    videoPixelSize.width *= [filteredVideoView contentScaleFactor];
//    videoPixelSize.height *= [filteredVideoView contentScaleFactor];
    
    CGSize videoPixelSize = CGSizeMake(480.0, 640.0);
    
    positionRawData = [[GPUImageRawDataOutput alloc] initWithImageSize:videoPixelSize resultsInBGRAFormat:YES];
    __unsafe_unretained ColorTrackingViewController *weakSelf = self;
    [positionRawData setNewFrameAvailableBlock:^{
        GLubyte *bytesForPositionData = positionRawData.rawBytesForImage;
        CGPoint currentTrackingLocation = [weakSelf centroidFromTexture:bytesForPositionData ofSize:[positionRawData maximumOutputSize]];
//        NSLog(@"Centroid from CPU: %f, %f", currentTrackingLocation.x, currentTrackingLocation.y);
        CGSize currentViewSize = weakSelf.view.bounds.size;
        dispatch_async(dispatch_get_main_queue(), ^{
            trackingDot.position = CGPointMake(currentTrackingLocation.x * currentViewSize.width, currentTrackingLocation.y * currentViewSize.height);
        });
    }];
    
    positionAverageColor = [[GPUImageAverageColor alloc] init];
    [positionAverageColor setColorAverageProcessingFinishedBlock:^(CGFloat redComponent, CGFloat greenComponent, CGFloat blueComponent, CGFloat alphaComponent, CMTime frameTime) {
//        NSLog(@"GPU Average R: %f, G: %f, A: %f", redComponent, greenComponent, alphaComponent);
        CGPoint currentTrackingLocation = CGPointMake(1.0 - (greenComponent / alphaComponent), (redComponent / alphaComponent));
//        NSLog(@"Centroid from GPU: %f, %f", currentTrackingLocation.x, currentTrackingLocation.y);
        //                NSLog(@"Average color: %f, %f, %f, %f", redComponent, greenComponent, blueComponent, alphaComponent);
        CGSize currentViewSize = weakSelf.view.bounds.size;
        dispatch_async(dispatch_get_main_queue(), ^{
            trackingDot.position = CGPointMake(currentTrackingLocation.x * currentViewSize.width, currentTrackingLocation.y * currentViewSize.height);
        });
    }];
    
    videoRawData = [[GPUImageRawDataOutput alloc] initWithImageSize:videoPixelSize resultsInBGRAFormat:YES];
    [videoRawData setNewFrameAvailableBlock:^{
        if (shouldReplaceThresholdColor)
        {
            CGSize currentViewSize = self.view.bounds.size;
            CGSize rawPixelsSize = [videoRawData maximumOutputSize];
            
            
            CGPoint scaledTouchPoint;
            scaledTouchPoint.x = (currentTouchPoint.x / currentViewSize.width) * rawPixelsSize.width;
            scaledTouchPoint.y = (currentTouchPoint.y / currentViewSize.height) * rawPixelsSize.height;
            
            GPUByteColorVector colorAtTouchPoint = [videoRawData colorAtLocation:scaledTouchPoint];
            
            thresholdColor.one = (float)colorAtTouchPoint.red / 255.0;
            thresholdColor.two = (float)colorAtTouchPoint.green / 255.0;
            thresholdColor.three = (float)colorAtTouchPoint.blue / 255.0;
            
            //            NSLog(@"Color at touch point: %d, %d, %d, %d", colorAtTouchPoint.red, colorAtTouchPoint.green, colorAtTouchPoint.blue, colorAtTouchPoint.alpha);
            
            [[NSUserDefaults standardUserDefaults] setFloat:thresholdColor.one forKey:@"thresholdColorR"];
            [[NSUserDefaults standardUserDefaults] setFloat:thresholdColor.two forKey:@"thresholdColorG"];
            [[NSUserDefaults standardUserDefaults] setFloat:thresholdColor.three forKey:@"thresholdColorB"];
            
            [thresholdFilter setFloatVec3:thresholdColor forUniformName:@"inputColor"];
            [positionFilter setFloatVec3:thresholdColor forUniformName:@"inputColor"];
            
            shouldReplaceThresholdColor = NO;
        }
    }];

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
//                [positionFilter addTarget:positionRawData]; // Enable this for CPU-based centroid computation
                [positionFilter addTarget:positionAverageColor]; // Enable this for GPU-based centroid computation
            }; break;
        }
    }    
}

#pragma mark -
#pragma mark Image processing

- (CGPoint)centroidFromTexture:(GLubyte *)pixels ofSize:(CGSize)textureSize;
{
	CGFloat currentXTotal = 0.0f, currentYTotal = 0.0f, currentPixelTotal = 0.0f;
	
    if ([GPUImageContext supportsFastTextureUpload]) 
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
    
//    NSLog(@"CPU Average R: %f, G: %f, A: %f", currentXTotal / (textureSize.width * textureSize.height), currentYTotal / (textureSize.width * textureSize.height), currentPixelTotal / (textureSize.width * textureSize.height));
	
	return CGPointMake((1.0 - currentYTotal / currentPixelTotal), currentXTotal / currentPixelTotal);
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

    [thresholdFilter setFloat:thresholdSensitivity forUniformName:@"threshold"];
    [positionFilter setFloat:thresholdSensitivity forUniformName:@"threshold"];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
}


@end

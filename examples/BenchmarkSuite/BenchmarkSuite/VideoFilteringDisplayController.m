#import "VideoFilteringDisplayController.h"

@implementation VideoFilteringDisplayController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self displayVideoForCPU];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Video filtering

- (void)startAVFoundationVideoProcessing;
{
    // Grab the back-facing camera
	AVCaptureDevice *backFacingCamera = nil;
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) 
	{
		if ([device position] == AVCaptureDevicePositionBack)
		{
			backFacingCamera = device;
		}
	}
    
	// Create the capture session
	captureSession = [[AVCaptureSession alloc] init];
	
	// Add the video input	
	NSError *error = nil;
	videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCamera error:&error];
	if ([captureSession canAddInput:videoInput]) 
	{
		[captureSession addInput:videoInput];
	}
	
	// Add the video frame output	
	videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	[videoOutput setAlwaysDiscardsLateVideoFrames:YES];
	// Use RGB frames instead of YUV to ease color processing
	[videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    //	dispatch_queue_t videoQueue = dispatch_queue_create("com.sunsetlakesoftware.colortracking.videoqueue", NULL);
    //	[videoOutput setSampleBufferDelegate:self queue:videoQueue];
    
	[videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
	if ([captureSession canAddOutput:videoOutput])
	{
		[captureSession addOutput:videoOutput];
	}
	else
	{
		NSLog(@"Couldn't add video output");
	}
    
    [captureSession setSessionPreset:AVCaptureSessionPreset640x480];
}

- (void)displayVideoForCPU;
{
    NSLog(@"Start CPU Image");
    totalFrameTimeForCPU = 0.0;
    numberOfCPUFramesCaptured = 0;

    [self startAVFoundationVideoProcessing];
    processUsingCPU = YES;
    
    [captureSession startRunning];
    
    double delayInSeconds = 10.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

        [captureSession stopRunning];
        // Remove view
        captureSession = nil;
        videoInput = nil;
        videoOutput = nil;
        
        NSLog(@"End CPU Image");

        [self displayVideoForCoreImage];
    });
}

- (void)displayVideoForCoreImage;
{
    totalFrameTimeForCoreImage = 0.0;
    numberOfCoreImageFramesCaptured = 0;

    NSLog(@"Start Core Image");

    self.openGLESContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.openGLESContext) {
        NSLog(@"Failed to create ES context");
    }

    [EAGLContext setCurrentContext:self.openGLESContext];

    videoDisplayView = [[GLKView alloc] initWithFrame:self.view.bounds context:self.openGLESContext];
//    videoDisplayView.frame = self.view.bounds;
    [self.view addSubview:videoDisplayView];
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);

//    videoDisplayView.context = self.openGLESContext;
//    videoDisplayView.drawableDepthFormat = GLKViewDrawableDepthFormat24;

//    [videoDisplayView bindDrawable];

    coreImageContext = [CIContext contextWithEAGLContext:self.openGLESContext];

    
    
    sepiaCoreImageFilter = [CIFilter filterWithName:@"CISepiaTone"];
    [sepiaCoreImageFilter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputIntensity"];
    
    [self startAVFoundationVideoProcessing];
    processUsingCPU = NO;
    
    [captureSession startRunning];    

    double delayInSeconds = 10.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [captureSession stopRunning];
        
        [videoDisplayView removeFromSuperview];
        videoDisplayView = nil;

        captureSession = nil;
        videoInput = nil;
        videoOutput = nil;
        
        self.openGLESContext = nil;
        glDeleteRenderbuffers(1, &_renderBuffer);

        NSLog(@"End Core Image");

        [self displayVideoForGPUImage];
    });
}

- (void)displayVideoForGPUImage;
{
    totalFrameTimeForGPUImage = 0.0;
    numberOfGPUImageFramesCaptured = 0;

    NSLog(@"Start GPU Image");
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.runBenchmark = YES;
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    
    [videoCamera addTarget:sepiaFilter];
    filterView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:filterView];
    [sepiaFilter addTarget:filterView];
    
    [videoCamera startCameraCapture];

    double delayInSeconds = 10.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [videoCamera stopCameraCapture];
        
        [filterView removeFromSuperview];
        filterView = nil;
        
        captureSession = nil;
        videoInput = nil;
        videoOutput = nil;
        
        NSLog(@"End GPU Image");
        
        [delegate finishedTestWithAverageTimesForCPU:(totalFrameTimeForCPU * 1000.0 / numberOfCPUFramesCaptured) coreImage:(totalFrameTimeForCoreImage * 1000.0 / numberOfCoreImageFramesCaptured) gpuImage:[videoCamera averageFrameDurationDuringCapture]];
        videoCamera = nil;
    });

}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection 
{
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);

    if (processUsingCPU)
    {
        // I only do the pixel processing here, not any upload to the view yet
        // Still, this should be sufficient to get a conservative estimate of the performance of a CPU-bound filtering routine
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);

        CFAbsoluteTime elapsedTime, startTime = CFAbsoluteTimeGetCurrent();

        unsigned char *data = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
//		int bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);

        int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
        int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
        NSInteger myDataLength = bufferWidth * bufferHeight * 4;
        
        
        for (int i = 0; i < myDataLength; i+=4)
        {
            UInt8 r_pixel = data[i];
            UInt8 g_pixel = data[i+1];
            UInt8 b_pixel = data[i+2];
            
            int outputRed = (r_pixel * .393) + (g_pixel *.769) + (b_pixel * .189);
            int outputGreen = (r_pixel * .349) + (g_pixel *.686) + (b_pixel * .168);
            int outputBlue = (r_pixel * .272) + (g_pixel *.534) + (b_pixel * .131);
            
            if(outputRed>255)outputRed=255;
            if(outputGreen>255)outputGreen=255;
            if(outputBlue>255)outputBlue=255;
            
            
            data[i] = outputRed;
            data[i+1] = outputGreen;
            data[i+2] = outputBlue;
        }

        elapsedTime = CFAbsoluteTimeGetCurrent() - startTime;
        
//        NSLog(@"CPU frame time: %f", elapsedTime * 1000.0);
        totalFrameTimeForCPU += elapsedTime;
        numberOfCPUFramesCaptured++;
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
    else
    {
        CFAbsoluteTime elapsedTime, startTime = CFAbsoluteTimeGetCurrent();

        CIImage *inputImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        inputImage = [inputImage imageByApplyingTransform:CGAffineTransformMakeRotation(-M_PI / 2.0)];
        [sepiaCoreImageFilter setValue:inputImage forKey:kCIInputImageKey];
        
        CIImage *outputImage = [sepiaCoreImageFilter outputImage];

        [coreImageContext drawImage:outputImage atPoint:CGPointMake(0.0, 0.0) fromRect:[inputImage extent]];
        
        [self.openGLESContext presentRenderbuffer:GL_RENDERBUFFER];
        elapsedTime = CFAbsoluteTimeGetCurrent() - startTime;
        
//        NSLog(@"Core Image frame time: %f", elapsedTime * 1000.0);

        totalFrameTimeForCoreImage += elapsedTime;
        numberOfCoreImageFramesCaptured++;
    }
}


#pragma mark -
#pragma mark Accessors

@synthesize delegate;
@synthesize openGLESContext;

@end

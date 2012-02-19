#import "GPUImageVideoCamera.h"

#pragma mark -
#pragma mark Private methods and instance variables

@interface GPUImageVideoCamera () 
{
	AVCaptureDeviceInput *videoInput;
	AVCaptureVideoDataOutput *videoOutput;
}

@end

@implementation GPUImageVideoCamera

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack]))
    {
		return nil;
    }

    return self;
}

- (id)initWithSessionPreset:(NSString *)sessionPreset cameraPosition:(AVCaptureDevicePosition)cameraPosition; 
{
	if (!(self = [super init]))
    {
		return nil;
    }
    
    runBenchmark = NO;
    
	// Grab the back-facing camera
	AVCaptureDevice *backFacingCamera = nil;
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) 
	{
		if ([device position] == cameraPosition)
		{
			backFacingCamera = device;
		}
	}
    	
	// Create the capture session
	captureSession = [[AVCaptureSession alloc] init];
	
    [captureSession beginConfiguration];

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
    
    [captureSession setSessionPreset:sessionPreset];
    [captureSession commitConfiguration];

//    inputTextureSize
    	
	return self;
}

- (void)dealloc 
{
    [self stopCameraCapture];
//    [videoOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];    
    
    [captureSession removeInput:videoInput];
    [captureSession removeOutput:videoOutput];

	[captureSession release];
	[videoOutput release];
	[videoInput release];

	[super dealloc];
}

#pragma mark -
#pragma mark Manage the camera video stream

- (void)startCameraCapture;
{
    if (![captureSession isRunning])
	{
		[captureSession startRunning];
	};
}

- (void)stopCameraCapture;
{
    if ([captureSession isRunning])
    {
        [captureSession stopRunning];
    }
}

#pragma mark -
#pragma mark Benchmarking

- (CGFloat)averageFrameDurationDuringCapture;
{
    NSLog(@"Number of frames: %d", numberOfFramesCaptured);
    return (totalFrameTimeDuringCapture / (CGFloat)numberOfFramesCaptured) * 1000.0;
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    // TODO: Update this with faster iOS 5.0 texture upload path
	CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Upload to texture
	CVPixelBufferLockBaseAddress(cameraFrame, 0);
	int bufferHeight = CVPixelBufferGetHeight(cameraFrame);
	int bufferWidth = CVPixelBufferGetWidth(cameraFrame);
	
    glBindTexture(GL_TEXTURE_2D, outputTexture);
	// Using BGRA extension to pull in video frame data directly
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
    
    for (id<GPUImageInput> currentTarget in targets)
    {
        [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight)];
        [currentTarget newFrameReady];
    }

	CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    
    if (runBenchmark)
    {
        CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
        totalFrameTimeDuringCapture += currentFrameTime;
        numberOfFramesCaptured++;
//        NSLog(@"Average frame time : %f ms", 1000.0 * (totalFrameTimeDuringCapture / numberOfFramesCaptured));
//        NSLog(@"Current frame time : %f ms", 1000.0 * currentFrameTime);
    }
}

#pragma mark -
#pragma mark Accessors

@synthesize captureSession;
@synthesize runBenchmark;

@end

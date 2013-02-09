#import "GPUImageVideoCamera.h"
#import "GPUImageMovieWriter.h"
#import "GPUImageFilter.h"

NSString *const kGPUImageYUVVideoRangeConversionForRGFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).rg - vec2(0.5, 0.5);
     
     // BT.601, which is the standard for SDTV is provided as a reference
     /*
      rgb = mat3(      1,       1,       1,
      0, -.39465, 2.03211,
      1.13983, -.58060,       0) * yuv;
      */
     
     // Using BT.709 which is the standard for HDTV
     rgb = mat3(      1,       1,       1,
                0, -.21482, 2.12798,
                1.28033, -.38059,       0) * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
);

NSString *const kGPUImageYUVVideoRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     
     // BT.601, which is the standard for SDTV is provided as a reference
     /*
      rgb = mat3(      1,       1,       1,
      0, -.39465, 2.03211,
      1.13983, -.58060,       0) * yuv;
      */
     
     // Using BT.709 which is the standard for HDTV
     rgb = mat3(      1,       1,       1,
                0, -.21482, 2.12798,
                1.28033, -.38059,       0) * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );


#pragma mark -
#pragma mark Private methods and instance variables

@interface GPUImageVideoCamera () 
{
	AVCaptureDeviceInput *audioInput;
	AVCaptureAudioDataOutput *audioOutput;
    NSDate *startingCaptureTime;
	
	NSInteger _frameRate;
    
    dispatch_queue_t cameraProcessingQueue, audioProcessingQueue;
    
    GLProgram *yuvConversionProgram;
    GLint yuvConversionPositionAttribute, yuvConversionTextureCoordinateAttribute;
    GLint yuvConversionLuminanceTextureUniform, yuvConversionChrominanceTextureUniform;
    GLuint yuvConversionFramebuffer;
    
    int imageBufferWidth, imageBufferHeight;
}

- (void)updateOrientationSendToTargets;
- (void)convertYUVToRGBOutput;
- (void)setYUVConversionFBO;

@end

@implementation GPUImageVideoCamera

@synthesize captureSessionPreset = _captureSessionPreset;
@synthesize captureSession = _captureSession;
@synthesize inputCamera = _inputCamera;
@synthesize runBenchmark = _runBenchmark;
@synthesize outputImageOrientation = _outputImageOrientation;
@synthesize delegate = _delegate;
@synthesize horizontallyMirrorFrontFacingCamera = _horizontallyMirrorFrontFacingCamera, horizontallyMirrorRearFacingCamera = _horizontallyMirrorRearFacingCamera;

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
    
	cameraProcessingQueue = dispatch_queue_create("com.sunsetlakesoftware.GPUImage.cameraProcessingQueue", NULL);
	audioProcessingQueue = dispatch_queue_create("com.sunsetlakesoftware.GPUImage.audioProcessingQueue", NULL);
    frameRenderingSemaphore = dispatch_semaphore_create(1);

	_frameRate = 0; // This will not set frame rate unless this value gets set to 1 or above
    _runBenchmark = NO;
    capturePaused = NO;
    outputRotation = kGPUImageNoRotation;
    captureAsYUV = YES;

    runSynchronouslyOnVideoProcessingQueue(^{
        
        if (captureAsYUV)
        {
            [GPUImageOpenGLESContext useImageProcessingContext];
//            if ([GPUImageOpenGLESContext deviceSupportsRedTextures])
//            {
//                yuvConversionProgram = [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageYUVVideoRangeConversionForRGFragmentShaderString];
//            }
//            else
//            {
                yuvConversionProgram = [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageYUVVideoRangeConversionForLAFragmentShaderString];
//            }

            if (!yuvConversionProgram.initialized)
            {
                [yuvConversionProgram addAttribute:@"position"];
                [yuvConversionProgram addAttribute:@"inputTextureCoordinate"];
                
                if (![yuvConversionProgram link])
                {
                    NSString *progLog = [yuvConversionProgram programLog];
                    NSLog(@"Program link log: %@", progLog);
                    NSString *fragLog = [yuvConversionProgram fragmentShaderLog];
                    NSLog(@"Fragment shader compile log: %@", fragLog);
                    NSString *vertLog = [yuvConversionProgram vertexShaderLog];
                    NSLog(@"Vertex shader compile log: %@", vertLog);
                    yuvConversionProgram = nil;
                    NSAssert(NO, @"Filter shader link failed");
                }
            }
            
            yuvConversionPositionAttribute = [yuvConversionProgram attributeIndex:@"position"];
            yuvConversionTextureCoordinateAttribute = [yuvConversionProgram attributeIndex:@"inputTextureCoordinate"];
            yuvConversionLuminanceTextureUniform = [yuvConversionProgram uniformIndex:@"luminanceTexture"];
            yuvConversionChrominanceTextureUniform = [yuvConversionProgram uniformIndex:@"chrominanceTexture"];
            
            [GPUImageOpenGLESContext setActiveShaderProgram:yuvConversionProgram];
            
            glEnableVertexAttribArray(yuvConversionPositionAttribute);
            glEnableVertexAttribArray(yuvConversionTextureCoordinateAttribute);
        }
        
        if ([GPUImageOpenGLESContext supportsFastTextureUpload])
        {
            [GPUImageOpenGLESContext useImageProcessingContext];
#if defined(__IPHONE_6_0)
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &coreVideoTextureCache);
#else
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &coreVideoTextureCache);
#endif
            if (err)
            {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
            }
            
            // Need to remove the initially created texture
//            [self deleteOutputTexture];
        }
        else
        {
            [self initializeOutputTextureIfNeeded];
        }
    });
    
	// Grab the back-facing or front-facing camera
    _inputCamera = nil;
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) 
	{
		if ([device position] == cameraPosition)
		{
			_inputCamera = device;
		}
	}
    
    if (!_inputCamera) {
        return nil;
    }
    
	// Create the capture session
	_captureSession = [[AVCaptureSession alloc] init];
	
    [_captureSession beginConfiguration];
    
	// Add the video input	
	NSError *error = nil;
	videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_inputCamera error:&error];
	if ([_captureSession canAddInput:videoInput]) 
	{
		[_captureSession addInput:videoInput];
	}
	
	// Add the video frame output	
	videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	[videoOutput setAlwaysDiscardsLateVideoFrames:NO];
    
//    if (captureAsYUV && [GPUImageOpenGLESContext deviceSupportsRedTextures])
    if (captureAsYUV && [GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        BOOL supportsFullYUVRange = NO;
        NSArray *supportedPixelFormats = videoOutput.availableVideoCVPixelFormatTypes;
        for (NSNumber *currentPixelFormat in supportedPixelFormats)
        {
            if ([currentPixelFormat intValue] == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            {
                supportsFullYUVRange = YES;
            }
        }
        
        if (supportsFullYUVRange)
        {
            [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        }
        else
        {
            [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        }
    }
    else
    {
        [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    }
    
    [videoOutput setSampleBufferDelegate:self queue:cameraProcessingQueue];
//    [videoOutput setSampleBufferDelegate:self queue:[GPUImageOpenGLESContext sharedOpenGLESQueue]];
	if ([_captureSession canAddOutput:videoOutput])
	{
		[_captureSession addOutput:videoOutput];
	}
	else
	{
		NSLog(@"Couldn't add video output");
        return nil;
	}
    
	_captureSessionPreset = sessionPreset;
    [_captureSession setSessionPreset:_captureSessionPreset];

// This will let you get 60 FPS video from the 720p preset on an iPhone 4S, but only that device and that preset
//    AVCaptureConnection *conn = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
//    
//    if (conn.supportsVideoMinFrameDuration)
//        conn.videoMinFrameDuration = CMTimeMake(1,60);
//    if (conn.supportsVideoMaxFrameDuration)
//        conn.videoMaxFrameDuration = CMTimeMake(1,60);
    
    [_captureSession commitConfiguration];
    
	return self;
}

- (void)dealloc 
{
    [self stopCameraCapture];
    [videoOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
    [audioOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
    
    [self removeInputsAndOutputs];
    
    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        CFRelease(coreVideoTextureCache);
    }

// ARC forbids explicit message send of 'release'; since iOS 6 even for dispatch_release() calls: stripping it out in that case is required.
#if ( (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0) || (!defined(__IPHONE_6_0)) )
    if (cameraProcessingQueue != NULL)
    {
        dispatch_release(cameraProcessingQueue);
    }

    if (audioProcessingQueue != NULL)
    {
        dispatch_release(audioProcessingQueue);
    }
    
    if (frameRenderingSemaphore != NULL)
    {
        dispatch_release(frameRenderingSemaphore);
    }
#endif
    
//    if (captureAsYUV && [GPUImageOpenGLESContext deviceSupportsRedTextures])
    if (captureAsYUV && [GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        [self destroyYUVConversionFBO];
    }
}

- (void)removeInputsAndOutputs;
{
    [_captureSession removeInput:videoInput];
    [_captureSession removeOutput:videoOutput];
    if (_microphone != nil)
    {
        [_captureSession removeInput:audioInput];
        [_captureSession removeOutput:audioOutput];
    }
}

#pragma mark -
#pragma mark Managing targets

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    [super addTarget:newTarget atTextureLocation:textureLocation];
    
    [newTarget setInputRotation:outputRotation atIndex:textureLocation];
}

#pragma mark -
#pragma mark Manage the camera video stream

- (void)startCameraCapture;
{
    if (![_captureSession isRunning])
	{
        startingCaptureTime = [NSDate date];
		[_captureSession startRunning];
	};
}

- (void)stopCameraCapture;
{
    if ([_captureSession isRunning])
    {
        [_captureSession stopRunning];
    }
}

- (void)pauseCameraCapture;
{
    capturePaused = YES;
}

- (void)resumeCameraCapture;
{
    capturePaused = NO;
}

- (void)rotateCamera
{
	if (self.frontFacingCameraPresent == NO)
		return;
	
    NSError *error;
    AVCaptureDeviceInput *newVideoInput;
    AVCaptureDevicePosition currentCameraPosition = [[videoInput device] position];
    
    if (currentCameraPosition == AVCaptureDevicePositionBack)
    {
        currentCameraPosition = AVCaptureDevicePositionFront;
    }
    else
    {
        currentCameraPosition = AVCaptureDevicePositionBack;
    }
    
    AVCaptureDevice *backFacingCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) 
	{
		if ([device position] == currentCameraPosition)
		{
			backFacingCamera = device;
		}
	}
    newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCamera error:&error];
    
    if (newVideoInput != nil)
    {
        [_captureSession beginConfiguration];
        
        [_captureSession removeInput:videoInput];
        if ([_captureSession canAddInput:newVideoInput])
        {
            [_captureSession addInput:newVideoInput];
            videoInput = newVideoInput;
        }
        else
        {
            [_captureSession addInput:videoInput];
        }
        //captureSession.sessionPreset = oriPreset;
        [_captureSession commitConfiguration];
    }
    
    _inputCamera = backFacingCamera;
    [self setOutputImageOrientation:_outputImageOrientation];
}

- (AVCaptureDevicePosition)cameraPosition 
{
    return [[videoInput device] position];
}

- (BOOL)isFrontFacingCameraPresent;
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == AVCaptureDevicePositionFront)
			return YES;
	}
	
	return NO;
}

- (void)setCaptureSessionPreset:(NSString *)captureSessionPreset;
{
	[_captureSession beginConfiguration];
	
	_captureSessionPreset = captureSessionPreset;
	[_captureSession setSessionPreset:_captureSessionPreset];
	
	[_captureSession commitConfiguration];
}

- (void)setFrameRate:(NSInteger)frameRate;
{
	_frameRate = frameRate;
	
	if (_frameRate > 0)
	{
		for (AVCaptureConnection *connection in videoOutput.connections)
		{
			if ([connection respondsToSelector:@selector(setVideoMinFrameDuration:)])
				connection.videoMinFrameDuration = CMTimeMake(1, _frameRate);
			
			if ([connection respondsToSelector:@selector(setVideoMaxFrameDuration:)])
				connection.videoMaxFrameDuration = CMTimeMake(1, _frameRate);
		}
	}
	else
	{
		for (AVCaptureConnection *connection in videoOutput.connections)
		{
			if ([connection respondsToSelector:@selector(setVideoMinFrameDuration:)])
				connection.videoMinFrameDuration = kCMTimeInvalid; // This sets videoMinFrameDuration back to default
			
			if ([connection respondsToSelector:@selector(setVideoMaxFrameDuration:)])
				connection.videoMaxFrameDuration = kCMTimeInvalid; // This sets videoMaxFrameDuration back to default
		}
	}
}

- (NSInteger)frameRate;
{
	return _frameRate;
}

- (AVCaptureConnection *)videoCaptureConnection {
    for (AVCaptureConnection *connection in [videoOutput connections] ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:AVMediaTypeVideo] ) {
				return connection;
			}
		}
	}
    
    return nil;
}

#define INITIALFRAMESTOIGNOREFORBENCHMARK 5

- (void)updateTargetsForVideoCameraUsingCacheTextureAtWidth:(int)bufferWidth height:(int)bufferHeight time:(CMTime)currentTime;
{
    for (id<GPUImageInput> currentTarget in targets)
    {
        if ([currentTarget enabled])
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            if (currentTarget != self.targetToIgnoreForUpdates)
            {
                [currentTarget setInputRotation:outputRotation atIndex:textureIndexOfTarget];
                [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:textureIndexOfTarget];
                
                if ([currentTarget wantsMonochromeInput] && captureAsYUV)
                {
                    [currentTarget setCurrentlyReceivingMonochromeInput:YES];
                    [currentTarget setInputTexture:luminanceTexture atIndex:textureIndexOfTarget];
                }
                else
                {
                    [currentTarget setCurrentlyReceivingMonochromeInput:NO];
                    [currentTarget setInputTexture:outputTexture atIndex:textureIndexOfTarget];
                }
                
                [currentTarget newFrameReadyAtTime:currentTime atIndex:textureIndexOfTarget];
            }
            else
            {
                [currentTarget setInputRotation:outputRotation atIndex:textureIndexOfTarget];
                [currentTarget setInputTexture:outputTexture atIndex:textureIndexOfTarget];
            }
        }
    }
}

- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
{
    if (capturePaused)
    {
        return;
    }
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = CVPixelBufferGetHeight(cameraFrame);
    
	CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

    [GPUImageOpenGLESContext useImageProcessingContext];

    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        CVOpenGLESTextureRef luminanceTextureRef = NULL;
        CVOpenGLESTextureRef chrominanceTextureRef = NULL;
        CVOpenGLESTextureRef texture = NULL;

//        if (captureAsYUV && [GPUImageOpenGLESContext deviceSupportsRedTextures])
        if (CVPixelBufferGetPlaneCount(cameraFrame) > 0) // Check for YUV planar inputs to do RGB conversion
        {
            
            if ( (imageBufferWidth != bufferWidth) && (imageBufferHeight != bufferHeight) )
            {
                imageBufferWidth = bufferWidth;
                imageBufferHeight = bufferHeight;
                
                [self destroyYUVConversionFBO];
                [self createYUVConversionFBO];
            }
            
            CVReturn err;
            // Y-plane
            glActiveTexture(GL_TEXTURE4);
            if ([GPUImageOpenGLESContext deviceSupportsRedTextures])
            {
//                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_RED_EXT, bufferWidth, bufferHeight, GL_RED_EXT, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
            }
            else
            {
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
            }
            if (err)
            {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            luminanceTexture = CVOpenGLESTextureGetName(luminanceTextureRef);
            glBindTexture(GL_TEXTURE_2D, luminanceTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            // UV-plane
            glActiveTexture(GL_TEXTURE5);
            if ([GPUImageOpenGLESContext deviceSupportsRedTextures])
            {
//                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_RG_EXT, bufferWidth/2, bufferHeight/2, GL_RG_EXT, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
            }
            else
            {
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
            }
            if (err)
            {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef);
            glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            if (!allTargetsWantMonochromeData)
            {
                [self convertYUVToRGBOutput];
            }

            [self updateTargetsForVideoCameraUsingCacheTextureAtWidth:bufferWidth height:bufferHeight time:currentTime];
            
            CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
            CVOpenGLESTextureCacheFlush(coreVideoTextureCache, 0);
            CFRelease(luminanceTextureRef);
            CFRelease(chrominanceTextureRef);
        }
        else
        {
            CVPixelBufferLockBaseAddress(cameraFrame, 0);
            
            CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_RGBA, bufferWidth, bufferHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &texture);
            
            if (!texture || err) {
                NSLog(@"Camera CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
                NSAssert(NO, @"Camera failure");
                return;
            }
            
            outputTexture = CVOpenGLESTextureGetName(texture);
            //        glBindTexture(CVOpenGLESTextureGetTarget(texture), outputTexture);
            glBindTexture(GL_TEXTURE_2D, outputTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            [self updateTargetsForVideoCameraUsingCacheTextureAtWidth:bufferWidth height:bufferHeight time:currentTime];

            CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
            CVOpenGLESTextureCacheFlush(coreVideoTextureCache, 0);
            CFRelease(texture);

            outputTexture = 0;
        }
        
        
        if (_runBenchmark)
        {
            numberOfFramesCaptured++;
            if (numberOfFramesCaptured > INITIALFRAMESTOIGNOREFORBENCHMARK)
            {
                CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
                totalFrameTimeDuringCapture += currentFrameTime;
                NSLog(@"Average frame time : %f ms", [self averageFrameDurationDuringCapture]);
                NSLog(@"Current frame time : %f ms", 1000.0 * currentFrameTime);
            }
        }
    }
    else
    {
        CVPixelBufferLockBaseAddress(cameraFrame, 0);
        
        glBindTexture(GL_TEXTURE_2D, outputTexture);
        
        //        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
        
        // Using BGRA extension to pull in video frame data directly
        // The use of bytesPerRow / 4 accounts for a display glitch present in preview video frames when using the photo preset on the camera
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(cameraFrame);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bytesPerRow / 4, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
        
        for (id<GPUImageInput> currentTarget in targets)
        {
            if ([currentTarget enabled])
            {
                if (currentTarget != self.targetToIgnoreForUpdates)
                {
                    NSInteger indexOfObject = [targets indexOfObject:currentTarget];
                    NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
                    
                    [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:textureIndexOfTarget];
                    [currentTarget newFrameReadyAtTime:currentTime atIndex:textureIndexOfTarget];
                }
            }
        }
        
        CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
        
        if (_runBenchmark)
        {
            numberOfFramesCaptured++;
            if (numberOfFramesCaptured > INITIALFRAMESTOIGNOREFORBENCHMARK)
            {
                CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
                totalFrameTimeDuringCapture += currentFrameTime;
            }
        }
    }  
}

- (void)processAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;
{
    [self.audioEncodingTarget processAudioBuffer:sampleBuffer]; 
}

- (void)convertYUVToRGBOutput;
{
    [GPUImageOpenGLESContext setActiveShaderProgram:yuvConversionProgram];
    [self setYUVConversionFBO];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, luminanceTexture);
	glUniform1i(yuvConversionLuminanceTextureUniform, 4);

    glActiveTexture(GL_TEXTURE5);
	glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
	glUniform1i(yuvConversionChrominanceTextureUniform, 5);

    glVertexAttribPointer(yuvConversionPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
	glVertexAttribPointer(yuvConversionTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)setYUVConversionFBO;
{
    if (!yuvConversionFramebuffer)
    {
        [self createYUVConversionFBO];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, yuvConversionFramebuffer);
    
    glViewport(0, 0, imageBufferWidth, imageBufferHeight);
}

- (void)createYUVConversionFBO;
{
    [self initializeOutputTextureIfNeeded];
    
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &yuvConversionFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, yuvConversionFramebuffer);
    
    glBindTexture(GL_TEXTURE_2D, outputTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageBufferWidth, imageBufferHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outputTexture, 0);
    
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    [self notifyTargetsAboutNewOutputTexture];

    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    glBindTexture(GL_TEXTURE_2D, 0);

}

- (void)destroyYUVConversionFBO;
{
    if (yuvConversionFramebuffer)
	{
		glDeleteFramebuffers(1, &yuvConversionFramebuffer);
		yuvConversionFramebuffer = 0;
	}
    
    if (outputTexture)
    {
        glDeleteTextures(1, &outputTexture);
        outputTexture = 0;
    }
}


#pragma mark -
#pragma mark Benchmarking

- (CGFloat)averageFrameDurationDuringCapture;
{
    return (totalFrameTimeDuringCapture / (CGFloat)(numberOfFramesCaptured - INITIALFRAMESTOIGNOREFORBENCHMARK)) * 1000.0;
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    __unsafe_unretained GPUImageVideoCamera *weakSelf = self;
    if (captureOutput == audioOutput)
    {
//        if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
//        {
//            return;
//        }

        CFRetain(sampleBuffer);
        runAsynchronouslyOnVideoProcessingQueue(^{
            [weakSelf processAudioSampleBuffer:sampleBuffer];
            CFRelease(sampleBuffer);
//            dispatch_semaphore_signal(frameRenderingSemaphore);
        });
    }
    else
    {
        if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
        {
            return;
        }

        CFRetain(sampleBuffer);
        runAsynchronouslyOnVideoProcessingQueue(^{
            //Feature Detection Hook.
            if (weakSelf.delegate)
            {
                [weakSelf.delegate willOutputSampleBuffer:sampleBuffer];
            }
            
            [weakSelf processVideoSampleBuffer:sampleBuffer];
            
            CFRelease(sampleBuffer);
            dispatch_semaphore_signal(frameRenderingSemaphore);
        });
    }
}

#pragma mark -
#pragma mark Accessors

- (void)setAudioEncodingTarget:(GPUImageMovieWriter *)newValue;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [_captureSession beginConfiguration];
        
        if (newValue == nil)
        {
            if (audioOutput)
            {
                [_captureSession removeInput:audioInput];
                [_captureSession removeOutput:audioOutput];
                audioInput = nil;
                audioOutput = nil;
                _microphone = nil;
            }
        }
        else
        {
            _microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            audioInput = [AVCaptureDeviceInput deviceInputWithDevice:_microphone error:nil];
            if ([_captureSession canAddInput:audioInput])
            {
                [_captureSession addInput:audioInput];
            }
            audioOutput = [[AVCaptureAudioDataOutput alloc] init];
            
            if ([_captureSession canAddOutput:audioOutput])
            {
                [_captureSession addOutput:audioOutput];
            }
            else
            {
                NSLog(@"Couldn't add audio output");
            }
            [audioOutput setSampleBufferDelegate:self queue:audioProcessingQueue];
        }
        
        [_captureSession commitConfiguration];
        
        [super setAudioEncodingTarget:newValue];
    });
}

- (void)updateOrientationSendToTargets;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        
        //    From the iOS 5.0 release notes:
        //    In previous iOS versions, the front-facing camera would always deliver buffers in AVCaptureVideoOrientationLandscapeLeft and the back-facing camera would always deliver buffers in AVCaptureVideoOrientationLandscapeRight.
        
        if ([self cameraPosition] == AVCaptureDevicePositionBack)
        {
            if (_horizontallyMirrorRearFacingCamera)
            {
                switch(_outputImageOrientation)
                {
                    case UIInterfaceOrientationPortrait:outputRotation = kGPUImageRotateRightFlipVertical; break;
                    case UIInterfaceOrientationPortraitUpsideDown:outputRotation = kGPUImageRotate180; break;
                    case UIInterfaceOrientationLandscapeLeft:outputRotation = kGPUImageFlipHorizonal; break;
                    case UIInterfaceOrientationLandscapeRight:outputRotation = kGPUImageFlipVertical; break;
                }
            }
            else
            {
                switch(_outputImageOrientation)
                {
                    case UIInterfaceOrientationPortrait:outputRotation = kGPUImageRotateRight; break;
                    case UIInterfaceOrientationPortraitUpsideDown:outputRotation = kGPUImageRotateLeft; break;
                    case UIInterfaceOrientationLandscapeLeft:outputRotation = kGPUImageNoRotation; break;
                    case UIInterfaceOrientationLandscapeRight:outputRotation = kGPUImageRotate180; break;
                }
            }
        }
        else
        {
            if (_horizontallyMirrorFrontFacingCamera)
            {
                switch(_outputImageOrientation)
                {
                    case UIInterfaceOrientationPortrait:outputRotation = kGPUImageRotateRight; break;
                    case UIInterfaceOrientationPortraitUpsideDown:outputRotation = kGPUImageRotateLeft; break;
                    case UIInterfaceOrientationLandscapeLeft:outputRotation = kGPUImageRotate180; break;
                    case UIInterfaceOrientationLandscapeRight:outputRotation = kGPUImageNoRotation; break;
                }
            }
            else
            {
                switch(_outputImageOrientation)
                {
                    case UIInterfaceOrientationPortrait:outputRotation = kGPUImageRotateRightFlipVertical; break;
                    case UIInterfaceOrientationPortraitUpsideDown:outputRotation = kGPUImageRotateRight; break;
                    case UIInterfaceOrientationLandscapeLeft:outputRotation = kGPUImageFlipVertical; break;
                    case UIInterfaceOrientationLandscapeRight:outputRotation = kGPUImageFlipHorizonal; break;
                }
            }
        }
        
        for (id<GPUImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            [currentTarget setInputRotation:outputRotation atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
        }
    });
}

- (void)setOutputImageOrientation:(UIInterfaceOrientation)newValue;
{
    _outputImageOrientation = newValue;
    [self updateOrientationSendToTargets];
}

- (void)setHorizontallyMirrorFrontFacingCamera:(BOOL)newValue
{
    _horizontallyMirrorFrontFacingCamera = newValue;
    [self updateOrientationSendToTargets];
}

- (void)setHorizontallyMirrorRearFacingCamera:(BOOL)newValue
{
    _horizontallyMirrorRearFacingCamera = newValue;
    [self updateOrientationSendToTargets];
}

@end

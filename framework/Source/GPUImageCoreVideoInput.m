//
//  GPUImageCoreVideoInput.m
//  GPUImage
//
//  Created by Karl von Randow on 3/11/13.
//  Copyright (c) 2013 Brad Larson. All rights reserved.
//

#import "GPUImageCoreVideoInput.h"

#import "GPUImageFilter.h"

// Color Conversion Constants (YUV to RGB) including adjustment from 16-235/16-240 (video range)

// BT.601, which is the standard for SDTV.
const GLfloat kColorConversion601[] = {
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0,
};

// BT.709, which is the standard for HDTV.
const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
const GLfloat kColorConversion601FullRange[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

NSString *const kGPUImageYUVVideoRangeConversionForRGFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).rg - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );

NSString *const kGPUImageYUVFullRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );

NSString *const kGPUImageYUVVideoRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r - (16.0/255.0);
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );

@interface GPUImageCoreVideoInput () {
    
    GLProgram *yuvConversionProgram;
    GLint yuvConversionPositionAttribute, yuvConversionTextureCoordinateAttribute;
    GLint yuvConversionLuminanceTextureUniform, yuvConversionChrominanceTextureUniform;
    GLint yuvConversionMatrixUniform;
    const GLfloat *_preferredConversion;
    
    int imageBufferWidth, imageBufferHeight;
}

- (void)convertYUVToRGBOutput;

@end
    
@implementation GPUImageCoreVideoInput

@synthesize runBenchmark = _runBenchmark;
@synthesize outputRotation = outputRotation;
@synthesize capturePaused = capturePaused;
@synthesize delegate = _delegate;

- (id)initWithCaptureAsYUV:(BOOL)aCaptureAsYUV fullYUVRange:(BOOL)fullYUVRange
{
    self = [super init];
    if (self) {
        frameRenderingSemaphore = dispatch_semaphore_create(1);
        
        _runBenchmark = NO;
        capturePaused = NO;
        outputRotation = kGPUImageNoRotation;
        internalRotation = kGPUImageNoRotation;
        captureAsYUV = aCaptureAsYUV;
        isFullYUVRange = fullYUVRange;
        _preferredConversion = kColorConversion709;
        
        runSynchronouslyOnVideoProcessingQueue(^{
            
            if (captureAsYUV)
            {
                [GPUImageContext useImageProcessingContext];
                //            if ([GPUImageContext deviceSupportsRedTextures])
                //            {
                //                yuvConversionProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageYUVVideoRangeConversionForRGFragmentShaderString];
                //            }
                //            else
                //            {
                if (isFullYUVRange)
                {
                    yuvConversionProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageYUVFullRangeConversionForLAFragmentShaderString];
                }
                else
                {
                    yuvConversionProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageYUVVideoRangeConversionForLAFragmentShaderString];
                }
                
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
                yuvConversionMatrixUniform = [yuvConversionProgram uniformIndex:@"colorConversionMatrix"];
                
                [GPUImageContext setActiveShaderProgram:yuvConversionProgram];
                
                glEnableVertexAttribArray(yuvConversionPositionAttribute);
                glEnableVertexAttribArray(yuvConversionTextureCoordinateAttribute);
            }
        });
    }
    return self;
}
 
- (GPUImageFramebuffer *)framebufferForOutput;
{
    return outputFramebuffer;
}

- (void)dealloc
{
    // ARC forbids explicit message send of 'release'; since iOS 6 even for dispatch_release() calls: stripping it out in that case is required.
#if ( (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0) || (!defined(__IPHONE_6_0)) )
    if (frameRenderingSemaphore != NULL)
    {
        dispatch_release(frameRenderingSemaphore);
    }
#endif
}

#define INITIALFRAMESTOIGNOREFORBENCHMARK 5

- (void)updateTargetsForVideoCameraUsingCacheTextureAtWidth:(int)bufferWidth height:(int)bufferHeight time:(CMTime)currentTime;
{
    // First, update all the framebuffers in the targets
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
                    // TODO: Replace optimization for monochrome output
                    [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
                }
                else
                {
                    [currentTarget setCurrentlyReceivingMonochromeInput:NO];
                    [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
                }
            }
            else
            {
                [currentTarget setInputRotation:outputRotation atIndex:textureIndexOfTarget];
                [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
            }
        }
    }
    
    // Then release our hold on the local framebuffer to send it back to the cache as soon as it's no longer needed
    [outputFramebuffer unlock];
    outputFramebuffer = nil;
    
    // Finally, trigger rendering as needed
    for (id<GPUImageInput> currentTarget in targets)
    {
        if ([currentTarget enabled])
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            if (currentTarget != self.targetToIgnoreForUpdates)
            {
                [currentTarget newFrameReadyAtTime:currentTime atIndex:textureIndexOfTarget];
            }
        }
    }
}

- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
{
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
	CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [self processPixelBuffer:cameraFrame atTime:currentTime];
}

- (void)processPixelBuffer:(CVPixelBufferRef)cameraFrame
                    atTime:(CMTime)currentTime
{
    if (capturePaused)
    {
        return;
    }
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
    CFTypeRef colorAttachments = CVBufferGetAttachment(cameraFrame, kCVImageBufferYCbCrMatrixKey, NULL);
    if (colorAttachments != NULL)
    {
        if(CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo)
        {
            if (isFullYUVRange)
            {
                _preferredConversion = kColorConversion601FullRange;
            }
            else
            {
                _preferredConversion = kColorConversion601;
            }
        }
        else
        {
            _preferredConversion = kColorConversion709;
        }
    }
    else
    {
        if (isFullYUVRange)
        {
            _preferredConversion = kColorConversion601FullRange;
        }
        else
        {
            _preferredConversion = kColorConversion601;
        }
    }
    
    [GPUImageContext useImageProcessingContext];
    
    if ([GPUImageContext supportsFastTextureUpload])
    {
        CVOpenGLESTextureRef luminanceTextureRef = NULL;
        CVOpenGLESTextureRef chrominanceTextureRef = NULL;
        
        //        if (captureAsYUV && [GPUImageContext deviceSupportsRedTextures])
        if (CVPixelBufferGetPlaneCount(cameraFrame) > 0) // Check for YUV planar inputs to do RGB conversion
        {
            
            if ( (imageBufferWidth != bufferWidth) && (imageBufferHeight != bufferHeight) )
            {
                imageBufferWidth = bufferWidth;
                imageBufferHeight = bufferHeight;
            }
            
            CVReturn err;
            // Y-plane
            glActiveTexture(GL_TEXTURE4);
            if ([GPUImageContext deviceSupportsRedTextures])
            {
                //                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_RED_EXT, bufferWidth, bufferHeight, GL_RED_EXT, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache], cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
            }
            else
            {
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache], cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
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
            if ([GPUImageContext deviceSupportsRedTextures])
            {
                //                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_RG_EXT, bufferWidth/2, bufferHeight/2, GL_RG_EXT, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache], cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
            }
            else
            {
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache], cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
            }
            if (err)
            {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef);
            glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            //            if (!allTargetsWantMonochromeData)
            //            {
            [self convertYUVToRGBOutput];
            //            }
            
            int rotatedImageBufferWidth = bufferWidth, rotatedImageBufferHeight = bufferHeight;
            
            if (GPUImageRotationSwapsWidthAndHeight(internalRotation))
            {
                rotatedImageBufferWidth = bufferHeight;
                rotatedImageBufferHeight = bufferWidth;
            }
            
            [self updateTargetsForVideoCameraUsingCacheTextureAtWidth:rotatedImageBufferWidth height:rotatedImageBufferHeight time:currentTime];
            
            CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
            CFRelease(luminanceTextureRef);
            CFRelease(chrominanceTextureRef);
        }
        else
        {
            // TODO: Mesh this with the output framebuffer structure
            
            //            CVPixelBufferLockBaseAddress(cameraFrame, 0);
            //
            //            CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache], cameraFrame, NULL, GL_TEXTURE_2D, GL_RGBA, bufferWidth, bufferHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &texture);
            //
            //            if (!texture || err) {
            //                NSLog(@"Camera CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
            //                NSAssert(NO, @"Camera failure");
            //                return;
            //            }
            //
            //            outputTexture = CVOpenGLESTextureGetName(texture);
            //            //        glBindTexture(CVOpenGLESTextureGetTarget(texture), outputTexture);
            //            glBindTexture(GL_TEXTURE_2D, outputTexture);
            //            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            //            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            //            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            //            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            //
            //            [self updateTargetsForVideoCameraUsingCacheTextureAtWidth:bufferWidth height:bufferHeight time:currentTime];
            //
            //            CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
            //            CFRelease(texture);
            //
            //            outputTexture = 0;
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
        
        int bytesPerRow = (int) CVPixelBufferGetBytesPerRow(cameraFrame);
        outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:CGSizeMake(bytesPerRow / 4, bufferHeight) onlyTexture:YES];
        [outputFramebuffer activateFramebuffer];
        
        glBindTexture(GL_TEXTURE_2D, [outputFramebuffer texture]);
        
        //        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
        
        // Using BGRA extension to pull in video frame data directly
        // The use of bytesPerRow / 4 accounts for a display glitch present in preview video frames when using the photo preset on the camera
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bytesPerRow / 4, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
        
        [self updateTargetsForVideoCameraUsingCacheTextureAtWidth:bytesPerRow / 4 height:bufferHeight time:currentTime];
        
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

- (void)convertYUVToRGBOutput;
{
    [GPUImageContext setActiveShaderProgram:yuvConversionProgram];
    
    int rotatedImageBufferWidth = imageBufferWidth, rotatedImageBufferHeight = imageBufferHeight;
    
    if (GPUImageRotationSwapsWidthAndHeight(internalRotation))
    {
        rotatedImageBufferWidth = imageBufferHeight;
        rotatedImageBufferHeight = imageBufferWidth;
    }
    
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:CGSizeMake(rotatedImageBufferWidth, rotatedImageBufferHeight) textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, luminanceTexture);
	glUniform1i(yuvConversionLuminanceTextureUniform, 4);
    
    glActiveTexture(GL_TEXTURE5);
	glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
	glUniform1i(yuvConversionChrominanceTextureUniform, 5);
    
    glUniformMatrix3fv(yuvConversionMatrixUniform, 1, GL_FALSE, _preferredConversion);
    
    glVertexAttribPointer(yuvConversionPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
	glVertexAttribPointer(yuvConversionTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [GPUImageFilter textureCoordinatesForRotation:internalRotation]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return;
    }
    
    CFRetain(sampleBuffer);
    runAsynchronouslyOnVideoProcessingQueue(^{
        //Feature Detection Hook.
        if (self.delegate)
        {
            [self.delegate willOutputSampleBuffer:sampleBuffer];
        }
        
        [self processVideoSampleBuffer:sampleBuffer];
        
        CFRelease(sampleBuffer);
        dispatch_semaphore_signal(frameRenderingSemaphore);
    });
}

- (BOOL)capturePixelBuffer:(CVPixelBufferRef)pixelBuffer atTime:(CMTime)time
{
    if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return NO;
    }
    
    CFRetain(pixelBuffer);
    runAsynchronouslyOnVideoProcessingQueue(^{
        [self processPixelBuffer:pixelBuffer atTime:time];
        
        CFRelease(pixelBuffer);
        dispatch_semaphore_signal(frameRenderingSemaphore);
    });
    
    return YES;
}

#pragma mark -
#pragma mark Managing targets

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    [super addTarget:newTarget atTextureLocation:textureLocation];
    
    [newTarget setInputRotation:outputRotation atIndex:textureLocation];
}

#pragma mark -
#pragma mark Benchmarking

- (CGFloat)averageFrameDurationDuringCapture;
{
    return (totalFrameTimeDuringCapture / (CGFloat)(numberOfFramesCaptured - INITIALFRAMESTOIGNOREFORBENCHMARK)) * 1000.0;
}

- (void)resetBenchmarkAverage;
{
    numberOfFramesCaptured = 0;
    totalFrameTimeDuringCapture = 0.0;
}

#pragma mark -
#pragma mark Accessors

- (void)setOutputRotation:(GPUImageRotationMode)anOutputRotation
{
    runSynchronouslyOnVideoProcessingQueue(^{
        outputRotation = anOutputRotation;
        
        for (id<GPUImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            [currentTarget setInputRotation:outputRotation atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
        }
    });
}

- (void)setInternalRotation:(GPUImageRotationMode)anInternalRotation
{
    internalRotation = anInternalRotation;
}

+ (GPUImageRotationMode)rotationForImageOrientation:(UIInterfaceOrientation)imageOrientation
                                    captureDevicePosition:(AVCaptureDevicePosition)position
                                    horizontallyMirrored:(BOOL)horizontallyMirrored
{
    if (position == AVCaptureDevicePositionBack)
    {
        if (horizontallyMirrored)
        {
            switch(imageOrientation)
            {
                case UIInterfaceOrientationPortrait:return kGPUImageRotateRightFlipVertical; break;
                case UIInterfaceOrientationPortraitUpsideDown:return kGPUImageRotate180; break;
                case UIInterfaceOrientationLandscapeLeft:return kGPUImageFlipHorizonal; break;
                case UIInterfaceOrientationLandscapeRight:return kGPUImageFlipVertical; break;
            }
        }
        else
        {
            switch(imageOrientation)
            {
                case UIInterfaceOrientationPortrait:return kGPUImageRotateRight; break;
                case UIInterfaceOrientationPortraitUpsideDown:return kGPUImageRotateLeft; break;
                case UIInterfaceOrientationLandscapeLeft:return kGPUImageRotate180; break;
                case UIInterfaceOrientationLandscapeRight:return kGPUImageNoRotation; break;
            }
        }
    }
    else
    {
        if (horizontallyMirrored)
        {
            switch(imageOrientation)
            {
                case UIInterfaceOrientationPortrait:return kGPUImageRotateRightFlipVertical; break;
                case UIInterfaceOrientationPortraitUpsideDown:return kGPUImageRotateRightFlipHorizontal; break;
                case UIInterfaceOrientationLandscapeLeft:return kGPUImageFlipHorizonal; break;
                case UIInterfaceOrientationLandscapeRight:return kGPUImageFlipVertical; break;
            }
        }
        else
        {
            switch(imageOrientation)
            {
                case UIInterfaceOrientationPortrait:return kGPUImageRotateRight; break;
                case UIInterfaceOrientationPortraitUpsideDown:return kGPUImageRotateLeft; break;
                case UIInterfaceOrientationLandscapeLeft:return kGPUImageNoRotation; break;
                case UIInterfaceOrientationLandscapeRight:return kGPUImageRotate180; break;
            }
        }
    }
}

@end

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageOutput.h"

/**
 A GPUImageOutput that provides frames from either camera
 
 From the iOS 5.0 release notes:
 _In previous iOS versions, the front-facing camera would always deliver buffers in AVCaptureVideoOrientationLandscapeLeft and the back-facing camera would always deliver buffers in AVCaptureVideoOrientationLandscapeRight._
 
 Currently, rotation is needed to handle each camera
*/
@interface GPUImageVideoCamera : GPUImageOutput <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{
    CVOpenGLESTextureCacheRef coreVideoTextureCache;    

    NSUInteger numberOfFramesCaptured;
    CGFloat totalFrameTimeDuringCapture;
    
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_inputCamera;
    AVCaptureDevice *_microphone;
    
    BOOL capturePaused;
}

/// The AVCaptureSession used to capture from the camera
@property(readonly, retain) AVCaptureSession *captureSession;

/// Whether or not benchmarking should be running
@property(readwrite, nonatomic) BOOL runBenchmark;

/// Use this property to manage camera settings. Focus point, exposure point, etc.
@property(readonly) AVCaptureDevice *inputCamera;

/// @name Initialization and teardown

/** Begin a capture session
 
 See AVCaptureSession for acceptable values
 
 @param sessionPreset Session preset to use
 @param cameraPosition Camera to capture from
 */
- (id)initWithSessionPreset:(NSString *)sessionPreset cameraPosition:(AVCaptureDevicePosition)cameraPosition;

/** Tear down the capture session
 */
- (void)removeInputsAndOutputs;

/// @name Manage the camera video stream

/** Start camera capturing
 */
- (void)startCameraCapture;

/** Stop camera capturing
 */
- (void)stopCameraCapture;

/** Pause camera capturing
 */
- (void)pauseCameraCapture;

/** Resume camera capturing
 */
- (void)resumeCameraCapture;

/** Process a video sample
 @param sampleBuffer Buffer to process
 */
- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/** Process an audio sample
 @param sampleBuffer Buffer to process
 */
- (void)processAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/** Get the position of the source camera
 */
- (AVCaptureDevicePosition)getCameraPosition;

/** Rotate the camera
 */
- (void)rotateCamera;

/// @name Benchmarking

/** Average frame duration
 */
- (CGFloat)averageFrameDurationDuringCapture;

@end

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageOutput.h"

// From the iOS 5.0 release notes:
// "In previous iOS versions, the front-facing camera would always deliver buffers in AVCaptureVideoOrientationLandscapeLeft and the back-facing camera would always deliver buffers in AVCaptureVideoOrientationLandscapeRight."
// Currently, rotation is needed to handle each camera

@interface GPUImageVideoCamera : GPUImageOutput <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{
    CVOpenGLESTextureCacheRef coreVideoTextureCache;    

    NSUInteger numberOfFramesCaptured;
    CGFloat totalFrameTimeDuringCapture;
    
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_inputCamera;
    AVCaptureDevice *_microphone;
}

@property(readonly, retain) AVCaptureSession *captureSession;
@property(readwrite, nonatomic) BOOL runBenchmark;

// Use this property to manage camera settings.Focus point, exposure point, etc.
@property(readonly) AVCaptureDevice *inputCamera;

// Initialization and teardown
- (id)initWithSessionPreset:(NSString *)sessionPreset cameraPosition:(AVCaptureDevicePosition)cameraPosition; 
- (void)removeInputsAndOutputs;

// Manage the camera video stream
- (void)startCameraCapture;
- (void)stopCameraCapture;
- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)processAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

// Rotate the camera
- (void)rotateCamera;

// Benchmarking
- (CGFloat)averageFrameDurationDuringCapture;

@end

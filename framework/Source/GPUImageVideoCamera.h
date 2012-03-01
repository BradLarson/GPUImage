#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageOutput.h"

// From the iOS 5.0 release notes:
// "In previous iOS versions, the front-facing camera would always deliver buffers in AVCaptureVideoOrientationLandscapeLeft and the back-facing camera would always deliver buffers in AVCaptureVideoOrientationLandscapeRight."
// Currently, rotation is needed to handle each camera

@interface GPUImageVideoCamera : GPUImageOutput <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *captureSession;
    CVOpenGLESTextureCacheRef coreVideoTextureCache;    

    NSUInteger numberOfFramesCaptured;
    CGFloat totalFrameTimeDuringCapture;
    BOOL runBenchmark;
}

@property(readonly) AVCaptureSession *captureSession;
@property(readwrite, nonatomic) BOOL runBenchmark;

// Initialization and teardown
- (id)initWithSessionPreset:(NSString *)sessionPreset cameraPosition:(AVCaptureDevicePosition)cameraPosition; 

// Manage fast texture upload
+ (BOOL)supportsFastTextureUpload;

// Manage the camera video stream
- (void)startCameraCapture;
- (void)stopCameraCapture;

// Benchmarking
- (CGFloat)averageFrameDurationDuringCapture;

@end

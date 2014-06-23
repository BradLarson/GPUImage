#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "GPUImage.h"

@protocol VideoFilteringCallback;

@interface VideoFilteringDisplayController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    CGFloat totalFrameTimeForCPU, totalFrameTimeForCoreImage, totalFrameTimeForGPUImage;
    NSUInteger numberOfCPUFramesCaptured, numberOfCoreImageFramesCaptured, numberOfGPUImageFramesCaptured;
    
    GLKView *videoDisplayView;
    AVCaptureSession *captureSession;
	AVCaptureDeviceInput *videoInput;
	AVCaptureVideoDataOutput *videoOutput;
    
    CIContext *coreImageContext;
    CIFilter *coreImageFilter;
    
    GLuint _renderBuffer;

    BOOL processUsingCPU;

    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *benchmarkedGPUImageFilter;
    GPUImageView *filterView;
    
    __unsafe_unretained id<VideoFilteringCallback> delegate;
}

@property(unsafe_unretained, nonatomic) id<VideoFilteringCallback> delegate;
@property (strong, nonatomic) EAGLContext *openGLESContext;

// Video filtering
- (void)startAVFoundationVideoProcessing;
- (void)displayVideoForCPU;
- (void)displayVideoForCoreImage;
- (void)displayVideoForGPUImage;

@end

@protocol VideoFilteringCallback

- (void)finishedTestWithAverageTimesForCPU:(CGFloat)cpuTime coreImage:(CGFloat)coreImageTime gpuImage:(CGFloat)gpuImageTime;

@end
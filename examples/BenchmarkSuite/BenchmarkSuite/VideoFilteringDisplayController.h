#import <UIKit/UIKit.h>

@protocol VideoFilteringCallback;

@interface VideoFilteringDisplayController : UIViewController
{
    CGFloat averageFrameTimeForCPU, averageFrameTimeForCoreImage, averageFrameTimeForGPUImage;
    
    __unsafe_unretained id<VideoFilteringCallback> delegate;
}

@property(unsafe_unretained, nonatomic) id<VideoFilteringCallback> delegate;

// Video filtering
- (void)displayVideoForCPU;
- (void)displayVideoForCoreImage;
- (void)displayVideoForGPUImage;

@end

@protocol VideoFilteringCallback

- (void)finishedTestWithAverageTimesForCPU:(CGFloat)cpuTime coreImage:(CGFloat)coreImageTime gpuImage:(CGFloat)gpuImageTime;

@end
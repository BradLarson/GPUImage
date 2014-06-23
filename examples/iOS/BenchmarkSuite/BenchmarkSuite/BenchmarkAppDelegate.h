#import <UIKit/UIKit.h>
@class ImageFilteringBenchmarkController, VideoFilteringBenchmarkController;

@interface BenchmarkAppDelegate : UIResponder <UIApplicationDelegate>
{
    UITabBarController *mainTabBarController;
    ImageFilteringBenchmarkController *imageFilteringBenchmarkController;
    VideoFilteringBenchmarkController *videoFilteringBenchmarkController;
}

@property (strong, nonatomic) UIWindow *window;

@end

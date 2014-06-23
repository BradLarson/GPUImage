#import "BenchmarkTableViewController.h"
#import "VideoFilteringDisplayController.h"

@interface VideoFilteringBenchmarkController : BenchmarkTableViewController<VideoFilteringCallback>
{
    VideoFilteringDisplayController *videoFilteringDisplayController;
}

@end

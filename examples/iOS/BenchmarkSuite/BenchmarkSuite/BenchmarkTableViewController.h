#import <UIKit/UIKit.h>

@interface BenchmarkTableViewController : UITableViewController
{
    CGFloat processingTimeForCPURoutine, processingTimeForCoreImageRoutine, processingTimeForGPUImageRoutine;
}

// Benchmarks
- (void)runBenchmark;

@end

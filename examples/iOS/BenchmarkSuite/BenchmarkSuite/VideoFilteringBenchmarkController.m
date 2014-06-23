#import "VideoFilteringBenchmarkController.h"

@implementation VideoFilteringBenchmarkController

#pragma mark -
#pragma mark Benchmarks

- (void)runBenchmark;
{
    videoFilteringDisplayController = [[VideoFilteringDisplayController alloc] initWithNibName:@"VideoFilteringDisplayController" bundle:nil];
    videoFilteringDisplayController.delegate = self;

    [self presentModalViewController:videoFilteringDisplayController animated:YES];

}

- (void)finishedTestWithAverageTimesForCPU:(CGFloat)cpuTime coreImage:(CGFloat)coreImageTime gpuImage:(CGFloat)gpuImageTime;
{
    [self dismissModalViewControllerAnimated:YES];
    
    processingTimeForCPURoutine = cpuTime;
    processingTimeForCoreImageRoutine = coreImageTime;
    processingTimeForGPUImageRoutine = gpuImageTime;
    
    [self.tableView reloadData];
}

@end

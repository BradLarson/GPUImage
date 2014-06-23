#import "BenchmarkTableViewController.h"

@interface ImageFilteringBenchmarkController : BenchmarkTableViewController
{
    CIContext *coreImageContext;
}

// Still image benchmarks
- (UIImage *)imageProcessedOnCPU:(UIImage *)imageToProcess;
- (UIImage *)imageProcessedUsingCoreImage:(UIImage *)imageToProcess;
- (UIImage *)imageProcessedUsingGPUImage:(UIImage *)imageToProcess;
- (void)writeImage:(UIImage *)imageToWrite toFile:(NSString *)fileName;

@end

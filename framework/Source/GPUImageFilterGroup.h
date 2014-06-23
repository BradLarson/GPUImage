#import "GPUImageOutput.h"
#import "GPUImageFilter.h"

@interface GPUImageFilterGroup : GPUImageOutput <GPUImageInput>
{
    NSMutableArray *filters;
    BOOL isEndProcessing;
}

@property(readwrite, nonatomic, strong) GPUImageOutput<GPUImageInput> *terminalFilter;
@property(readwrite, nonatomic, strong) NSArray *initialFilters;
@property(readwrite, nonatomic, strong) GPUImageOutput<GPUImageInput> *inputFilterToIgnoreForUpdates; 

// Filter management
- (void)addFilter:(GPUImageOutput<GPUImageInput> *)newFilter;
- (GPUImageOutput<GPUImageInput> *)filterAtIndex:(NSUInteger)filterIndex;
- (NSUInteger)filterCount;

@end

#import "GPUImageOutput.h"
#import "GPUImageFilter.h"

@interface GPUImageFilterGroup : GPUImageOutput <GPUImageInput, GPUImageTextureDelegate>
{
    NSMutableArray *filters;
}

@property(readwrite, nonatomic, strong) GPUImageOutput<GPUImageInput> *terminalFilter;
@property(readwrite, nonatomic, strong) NSArray *initialFilters;
@property(readwrite, nonatomic, strong) GPUImageOutput<GPUImageInput> *inputFilterToIgnoreForUpdates; 

// Filter management
- (void)addFilter:(GPUImageOutput<GPUImageInput> *)newFilter;
- (GPUImageOutput<GPUImageInput> *)filterAtIndex:(NSUInteger)filterIndex;
- (int)filterCount;

@end

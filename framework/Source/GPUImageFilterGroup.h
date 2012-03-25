#import "GPUImageOutput.h"

@class GPUImageFilter;

@interface GPUImageFilterGroup : GPUImageOutput <GPUImageInput>
{
    NSMutableArray *filters;
}

@property(readonly, nonatomic) GPUImageFilter *initialFilter;
@property(readonly, nonatomic) GPUImageFilter *terminalFilter;

// Filter management
- (void)addFilter:(GPUImageFilter *)newFilter;
- (void)setTargetFilter:(GPUImageFilter *)targetFilter forFilter:(GPUImageFilter *)sourceFilter;
- (GPUImageFilter *)filterAtIndex:(NSUInteger)filterIndex;

@end

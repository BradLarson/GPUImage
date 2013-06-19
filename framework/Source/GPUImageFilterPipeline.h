#import <Foundation/Foundation.h>
#import "GPUImageFilter.h"

@interface GPUImageFilterPipeline : NSObject
{
    NSString *stringValue;
}

@property (strong) NSMutableArray *filters;

@property (strong) GPUImageOutput *input;
@property (strong) id <GPUImageInput> output;

- (id) initWithOrderedFilters:(NSArray*) filters input:(GPUImageOutput*)input output:(id <GPUImageInput>)output;
- (id) initWithConfiguration:(NSDictionary*) configuration input:(GPUImageOutput*)input output:(id <GPUImageInput>)output;
- (id) initWithConfigurationFile:(NSURL*) configuration input:(GPUImageOutput*)input output:(id <GPUImageInput>)output;

- (void) addFilter:(GPUImageFilter*)filter;
- (void) addFilter:(GPUImageFilter*)filter atIndex:(NSUInteger)insertIndex;
- (void) replaceFilterAtIndex:(NSUInteger)index withFilter:(GPUImageFilter*)filter;
- (void) replaceAllFilters:(NSArray*) newFilters;
- (void) removeFilterAtIndex:(NSUInteger)index;
- (void) removeAllFilters;

- (UIImage *) currentFilteredFrame;
- (UIImage *) currentFilteredFrameWithOrientation:(UIImageOrientation)imageOrientation;
- (CGImageRef) newCGImageFromCurrentFilteredFrame;
- (CGImageRef) newCGImageFromCurrentFilteredFrameWithOrientation:(UIImageOrientation)imageOrientation;

@end

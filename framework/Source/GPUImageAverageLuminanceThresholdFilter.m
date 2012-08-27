#import "GPUImageAverageLuminanceThresholdFilter.h"
#import "GPUImageLuminosity.h"
#import "GPUImageLuminanceThresholdFilter.h"

@interface GPUImageAverageLuminanceThresholdFilter()
{
    GPUImageLuminosity *luminosityFilter;
    GPUImageLuminanceThresholdFilter *luminanceThresholdFilter;
}
@end

@implementation GPUImageAverageLuminanceThresholdFilter

@synthesize thresholdMultiplier = _thresholdMultiplier;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    self.thresholdMultiplier = 1.0;
    
    luminosityFilter = [[GPUImageLuminosity alloc] init];
    [self addFilter:luminosityFilter];
    
    luminanceThresholdFilter = [[GPUImageLuminanceThresholdFilter alloc] init];
    [self addFilter:luminanceThresholdFilter];
    
    __unsafe_unretained GPUImageAverageLuminanceThresholdFilter *weakSelf = self;
    __unsafe_unretained GPUImageLuminanceThresholdFilter *weakThreshold = luminanceThresholdFilter;
    
    [luminosityFilter setLuminosityProcessingFinishedBlock:^(CGFloat luminosity, CMTime frameTime) {
        weakThreshold.threshold = luminosity * weakSelf.thresholdMultiplier;
    }];
    
    self.initialFilters = [NSArray arrayWithObjects:luminosityFilter, luminanceThresholdFilter, nil];
    self.terminalFilter = luminanceThresholdFilter;
    
    return self;
}

@end

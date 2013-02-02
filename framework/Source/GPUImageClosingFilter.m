#import "GPUImageClosingFilter.h"
#import "GPUImageErosionFilter.h"
#import "GPUImageDilationFilter.h"

@implementation GPUImageClosingFilter

- (id)init;
{
    if (!(self = [self initWithRadius:1]))
    {
		return nil;
    }
    
    return self;
}

- (id)initWithRadius:(NSUInteger)radius;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    // First pass: dilation
    dilationFilter = [[GPUImageDilationFilter alloc] initWithRadius:radius];
    [self addFilter:dilationFilter];
    
    // Second pass: erosion
    erosionFilter = [[GPUImageErosionFilter alloc] initWithRadius:radius];
    [self addFilter:erosionFilter];
    
    [dilationFilter addTarget:erosionFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:dilationFilter, nil];
    self.terminalFilter = erosionFilter;
    
    return self;
}

@end

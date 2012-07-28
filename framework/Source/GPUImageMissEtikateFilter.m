#import "GPUImageMissEtikateFilter.h"
#import "GPUImagePicture.h"
#import "GPUImageLookupFilter.h"

@implementation GPUImageMissEtikateFilter

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    lookupImageSource = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"lookup_miss_etikate.png"]];
    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];

    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];

    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;

    return self;
}

#pragma mark -
#pragma mark Accessors

@end

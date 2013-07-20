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

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *image = [UIImage imageNamed:@"lookup_miss_etikate.png"];
#else
    NSImage *image = [NSImage imageNamed:@"lookup_miss_etikate.png"];
#endif

    NSAssert(image, @"To use GPUImageMissEtikateFilter you need to add lookup_miss_etikate.png from GPUImage/framework/Resources to your application bundle.");

    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];

    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];

    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;

    return self;
}

-(void)prepareForImageCapture {
    [lookupImageSource processImage];
    [super prepareForImageCapture];
}

#pragma mark -
#pragma mark Accessors

@end

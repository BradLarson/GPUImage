#import "GPUImageSoftEleganceFilter.h"
#import "GPUImagePicture.h"
#import "GPUImageLookupFilter.h"
#import "GPUImageGaussianBlurFilter.h"
#import "GPUImageAlphaBlendFilter.h"

@implementation GPUImageSoftEleganceFilter

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    lookupImageSource1 = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"lookup_soft_elegance_1.png"]];
    GPUImageLookupFilter *lookupFilter1 = [[GPUImageLookupFilter alloc] init];

    [lookupImageSource1 addTarget:lookupFilter1 atTextureLocation:1];
    [lookupImageSource1 processImage];

    GPUImageGaussianBlurFilter *gaussianBlur = [[GPUImageGaussianBlurFilter alloc] init];
    gaussianBlur.blurSize = 9.7;
    [lookupFilter1 addTarget:gaussianBlur];
    
    GPUImageAlphaBlendFilter *alphaBlend = [[GPUImageAlphaBlendFilter alloc] init];
    alphaBlend.mix = 0.14;
    [lookupFilter1 addTarget:alphaBlend];
    [gaussianBlur addTarget:alphaBlend];
    
    lookupImageSource2 = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"lookup_soft_elegance_2.png"]];

    GPUImageLookupFilter *lookupFilter2 = [[GPUImageLookupFilter alloc] init];
    [alphaBlend addTarget:lookupFilter2];
    [lookupImageSource2 addTarget:lookupFilter2];
    [lookupImageSource2 processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:lookupFilter1, gaussianBlur, alphaBlend, lookupFilter2, nil];
    self.terminalFilter = lookupFilter2;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

@end

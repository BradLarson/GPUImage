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

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *image1 = [UIImage imageNamed:@"lookup_soft_elegance_1.png"];
    UIImage *image2 = [UIImage imageNamed:@"lookup_soft_elegance_2.png"];
#else
    NSImage *image1 = [NSImage imageNamed:@"lookup_soft_elegance_1.png"];
    NSImage *image2 = [NSImage imageNamed:@"lookup_soft_elegance_2.png"];
#endif

    NSAssert(image1 && image2,
             @"To use GPUImageSoftEleganceFilter you need to add lookup_soft_elegance_1.png and lookup_soft_elegance_2.png from GPUImage/framework/Resources to your application bundle.");
    
    lookupImageSource1 = [[GPUImagePicture alloc] initWithImage:image1];
    GPUImageLookupFilter *lookupFilter1 = [[GPUImageLookupFilter alloc] init];
    [self addFilter:lookupFilter1];

    [lookupImageSource1 addTarget:lookupFilter1 atTextureLocation:1];
    [lookupImageSource1 processImage];

    GPUImageGaussianBlurFilter *gaussianBlur = [[GPUImageGaussianBlurFilter alloc] init];
    gaussianBlur.blurRadiusInPixels = 10.0;
    [lookupFilter1 addTarget:gaussianBlur];
    [self addFilter:gaussianBlur];
    
    GPUImageAlphaBlendFilter *alphaBlend = [[GPUImageAlphaBlendFilter alloc] init];
    alphaBlend.mix = 0.14;
    [lookupFilter1 addTarget:alphaBlend];
    [gaussianBlur addTarget:alphaBlend];
    [self addFilter:alphaBlend];
    
    lookupImageSource2 = [[GPUImagePicture alloc] initWithImage:image2];

    GPUImageLookupFilter *lookupFilter2 = [[GPUImageLookupFilter alloc] init];
    [alphaBlend addTarget:lookupFilter2];
    [lookupImageSource2 addTarget:lookupFilter2];
    [lookupImageSource2 processImage];
    [self addFilter:lookupFilter2];
    
    self.initialFilters = [NSArray arrayWithObjects:lookupFilter1, nil];
    self.terminalFilter = lookupFilter2;
    
    return self;
}

-(void)prepareForImageCapture {
    [lookupImageSource1 processImage];
    [lookupImageSource2 processImage];
    [super prepareForImageCapture];
}

#pragma mark -
#pragma mark Accessors

@end

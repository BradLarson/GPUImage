#import "GPUImageSmartEyeSkinDetectSmoothCSEnhanceSaveKa.h"
#import "GPUImageSmartEyeSkinDetectSmoothCSEnhanceSave.h"
#import "GPUImagePicture.h"
#import <UIKit/UIKit.h>

@implementation GPUImageSmartEyeSkinDetectSmoothCSEnhanceSaveKa

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *image = [UIImage imageNamed:@"skindetect.png"];
#else
    NSImage *image = [NSImage imageNamed:@"skindetect.png"];
#endif
    
    NSAssert(image, @"To use GPUImageSmartEyeSkinDetectSmoothCSEnhanceSave you need to add sikndetect.png from GPUImage/framework/Resources to your application bundle.");
    
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageSmartEyeSkinDetectSmoothCSEnhanceSave *lookupFilter = [[GPUImageSmartEyeSkinDetectSmoothCSEnhanceSave alloc] init];
    [self addFilter:lookupFilter];
    
    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

@end

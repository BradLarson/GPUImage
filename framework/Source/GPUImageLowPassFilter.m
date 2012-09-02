#import "GPUImageLowPassFilter.h"

@implementation GPUImageLowPassFilter

@synthesize filterStrength;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    // Take in the frame and blend it with the previous one
    dissolveBlendFilter = [[GPUImageDissolveBlendFilter alloc] init];
    [self addFilter:dissolveBlendFilter];
    
    // Buffer the result to be fed back into the blend
    bufferFilter = [[GPUImageBuffer alloc] init];
    [self addFilter:bufferFilter];
    
    // Texture location 0 needs to be the original image for the dissolve blend
    [bufferFilter addTarget:dissolveBlendFilter atTextureLocation:1];
    [dissolveBlendFilter addTarget:bufferFilter];
    
    [dissolveBlendFilter disableSecondFrameCheck];
    
    // To prevent double updating of this filter, disable updates from the sharp image side
    //    self.inputFilterToIgnoreForUpdates = unsharpMaskFilter;
    
    self.initialFilters = [NSArray arrayWithObject:dissolveBlendFilter];
    self.terminalFilter = dissolveBlendFilter;
    
    self.filterStrength = 0.5;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setFilterStrength:(CGFloat)newValue;
{
    dissolveBlendFilter.mix = newValue;
}

- (CGFloat)filterStrength;
{
    return dissolveBlendFilter.mix;
}

@end

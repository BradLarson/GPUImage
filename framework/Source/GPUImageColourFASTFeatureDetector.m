#import "GPUImageColourFASTFeatureDetector.h"
#import "GPUImageColourFASTSamplingOperation.h"
#import "GPUImageBoxBlurFilter.h"

@implementation GPUImageColourFASTFeatureDetector

@synthesize blurRadiusInPixels;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    // First pass: apply a variable Gaussian blur
    blurFilter = [[GPUImageBoxBlurFilter alloc] init];
    [self addFilter:blurFilter];
        
    // Second pass: combine the blurred image with the original sharp one
    colourFASTSamplingOperation = [[GPUImageColourFASTSamplingOperation alloc] init];
    [self addFilter:colourFASTSamplingOperation];
    
    // Texture location 0 needs to be the sharp image for both the blur and the second stage processing
    [blurFilter addTarget:colourFASTSamplingOperation atTextureLocation:1];
    
    self.initialFilters = [NSArray arrayWithObjects:blurFilter, colourFASTSamplingOperation, nil];
    self.terminalFilter = colourFASTSamplingOperation;
    
    self.blurRadiusInPixels = 3.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setBlurRadiusInPixels:(CGFloat)newValue;
{
    blurFilter.blurRadiusInPixels = newValue;
}

- (CGFloat)blurRadiusInPixels;
{
    return blurFilter.blurRadiusInPixels;
}

@end
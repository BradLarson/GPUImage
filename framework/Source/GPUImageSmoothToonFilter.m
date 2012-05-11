#import "GPUImageSmoothToonFilter.h"
#import "GPUImageGaussianBlurFilter.h"
#import "GPUImageToonFilter.h"

@implementation GPUImageSmoothToonFilter

@synthesize threshold;
@synthesize blurSize;
@synthesize quantizationLevels;
@synthesize texelWidth;
@synthesize texelHeight;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    // First pass: apply a variable Gaussian blur
    blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
    [self addFilter:blurFilter];
    
    // Second pass: run the Sobel edge detection on this blurred image, along with a posterization effect
    toonFilter = [[GPUImageToonFilter alloc] init];
    [self addFilter:toonFilter];
    
    // Texture location 0 needs to be the sharp image for both the blur and the second stage processing
    [blurFilter addTarget:toonFilter];
    
    self.initialFilters = [NSArray arrayWithObject:blurFilter];
    self.terminalFilter = toonFilter;
    
    self.blurSize = 0.5;
    self.threshold = 0.2;
    self.quantizationLevels = 10.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setBlurSize:(CGFloat)newValue;
{
    blurFilter.blurSize = newValue;
}

- (CGFloat)blurSize;
{
    return blurFilter.blurSize;
}

- (void)setTexelWidth:(CGFloat)newValue;
{
    toonFilter.texelWidth = newValue;
}

- (CGFloat)texelWidth;
{
    return toonFilter.texelWidth;
}

- (void)setTexelHeight:(CGFloat)newValue;
{
    toonFilter.texelHeight = newValue;
}

- (CGFloat)texelHeight;
{
    return toonFilter.texelHeight;
}

- (void)setThreshold:(CGFloat)newValue;
{
    toonFilter.threshold = newValue;
}

- (CGFloat)threshold;
{
    return toonFilter.threshold;
}

- (void)setQuantizationLevels:(CGFloat)newValue;
{
    toonFilter.quantizationLevels = newValue;
}

- (CGFloat)quantizationLevels;
{
    return toonFilter.quantizationLevels;
}

@end

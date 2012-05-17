#import "GPUImageCannyEdgeDetectionFilter.h"
#import "GPUImageGaussianBlurFilter.h"
#import "GPUImageThresholdEdgeDetection.h"
#import "GPUImageSketchFilter.h"

@implementation GPUImageCannyEdgeDetectionFilter

@synthesize threshold;
@synthesize blurSize;
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
    
    // Second pass: run the Sobel edge detection on this blurred image
    edgeDetectionFilter = [[GPUImageThresholdEdgeDetection alloc] init];
//    edgeDetectionFilter = [[GPUImageSketchFilter alloc] init];
    [self addFilter:edgeDetectionFilter];
    
    // Texture location 0 needs to be the sharp image for both the blur and the second stage processing
    [blurFilter addTarget:edgeDetectionFilter];
    
    self.initialFilters = [NSArray arrayWithObject:blurFilter];
    self.terminalFilter = edgeDetectionFilter;
    
    self.blurSize = 1.5;
    self.threshold = 0.9;
    
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
    edgeDetectionFilter.texelWidth = newValue;
}

- (CGFloat)texelWidth;
{
    return edgeDetectionFilter.texelWidth;
}

- (void)setTexelHeight:(CGFloat)newValue;
{
    edgeDetectionFilter.texelHeight = newValue;
}

- (CGFloat)texelHeight;
{
    return edgeDetectionFilter.texelHeight;
}

- (void)setThreshold:(CGFloat)newValue;
{
    edgeDetectionFilter.threshold = newValue;
}

- (CGFloat)threshold;
{
    return edgeDetectionFilter.threshold;
//    return 0;
}

@end

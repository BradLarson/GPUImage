#import "GPUImageCannyEdgeDetectionFilter.h"

#import "GPUImageGrayscaleFilter.h"
#import "GPUImageDirectionalSobelEdgeDetectionFilter.h"
#import "GPUImageDirectionalNonMaximumSuppressionFilter.h"
#import "GPUImageWeakPixelInclusionFilter.h"
#import "GPUImageSingleComponentGaussianBlurFilter.h"

@implementation GPUImageCannyEdgeDetectionFilter

@synthesize upperThreshold;
@synthesize lowerThreshold;
@synthesize blurRadiusInPixels;
@synthesize blurTexelSpacingMultiplier;
@synthesize texelWidth;
@synthesize texelHeight;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    // First pass: convert image to luminance
    luminanceFilter = [[GPUImageGrayscaleFilter alloc] init];
    [self addFilter:luminanceFilter];
    
    // Second pass: apply a variable Gaussian blur
    blurFilter = [[GPUImageSingleComponentGaussianBlurFilter alloc] init];
    [self addFilter:blurFilter];
    
    // Third pass: run the Sobel edge detection, with calculated gradient directions, on this blurred image
    edgeDetectionFilter = [[GPUImageDirectionalSobelEdgeDetectionFilter alloc] init];
    [self addFilter:edgeDetectionFilter];
    
    // Fourth pass: apply non-maximum suppression    
    nonMaximumSuppressionFilter = [[GPUImageDirectionalNonMaximumSuppressionFilter alloc] init];
    [self addFilter:nonMaximumSuppressionFilter];
    
    // Fifth pass: include weak pixels to complete edges
    weakPixelInclusionFilter = [[GPUImageWeakPixelInclusionFilter alloc] init];
    [self addFilter:weakPixelInclusionFilter];
    
    [luminanceFilter addTarget:blurFilter];
    [blurFilter addTarget:edgeDetectionFilter];
    [edgeDetectionFilter addTarget:nonMaximumSuppressionFilter];
    [nonMaximumSuppressionFilter addTarget:weakPixelInclusionFilter];
    
    self.initialFilters = [NSArray arrayWithObject:luminanceFilter];
//    self.terminalFilter = nonMaximumSuppressionFilter;
    self.terminalFilter = weakPixelInclusionFilter;
    
    self.blurRadiusInPixels = 2.0;
    self.blurTexelSpacingMultiplier = 1.0;
    self.upperThreshold = 0.4;
    self.lowerThreshold = 0.1;
    
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

- (void)setBlurTexelSpacingMultiplier:(CGFloat)newValue;
{
    blurFilter.texelSpacingMultiplier = newValue;
}

- (CGFloat)blurTexelSpacingMultiplier;
{
    return blurFilter.texelSpacingMultiplier;
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

- (void)setUpperThreshold:(CGFloat)newValue;
{
    nonMaximumSuppressionFilter.upperThreshold = newValue;
}

- (CGFloat)upperThreshold;
{
    return nonMaximumSuppressionFilter.upperThreshold;
}

- (void)setLowerThreshold:(CGFloat)newValue;
{
    nonMaximumSuppressionFilter.lowerThreshold = newValue;
}

- (CGFloat)lowerThreshold;
{
    return nonMaximumSuppressionFilter.lowerThreshold;
}

@end

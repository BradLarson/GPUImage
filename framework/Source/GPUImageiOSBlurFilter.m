#import "GPUImageiOSBlurFilter.h"
#import "GPUImageSaturationFilter.h"
#import "GPUImageGaussianBlurFilter.h"
#import "GPUImageLuminanceRangeFilter.h"

@implementation GPUImageiOSBlurFilter

@synthesize blurRadiusInPixels;
@synthesize saturation;
@synthesize downsampling = _downsampling;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    // First pass: downsample and desaturate
    saturationFilter = [[GPUImageSaturationFilter alloc] init];
    [self addFilter:saturationFilter];
    
    // Second pass: apply a strong Gaussian blur
    blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
    [self addFilter:blurFilter];
    
    // Third pass: upsample and adjust luminance range
    luminanceRangeFilter = [[GPUImageLuminanceRangeFilter alloc] init];
    [self addFilter:luminanceRangeFilter];
        
    [saturationFilter addTarget:blurFilter];
    [blurFilter addTarget:luminanceRangeFilter];
    
    self.initialFilters = [NSArray arrayWithObject:saturationFilter];
    self.terminalFilter = luminanceRangeFilter;
    
    self.blurRadiusInPixels = 12.0;
    self.saturation = 0.8;
    self.downsampling = 4.0;
    self.rangeReductionFactor = 0.6;

    return self;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    if (_downsampling > 1.0)
    {
        CGSize rotatedSize = [saturationFilter rotatedSize:newSize forIndex:textureIndex];

        [saturationFilter forceProcessingAtSize:CGSizeMake(rotatedSize.width / _downsampling, rotatedSize.height / _downsampling)];
        [luminanceRangeFilter forceProcessingAtSize:rotatedSize];
    }
    
    [super setInputSize:newSize atIndex:textureIndex];
}

#pragma mark -
#pragma mark Accessors

// From Apple's UIImage+ImageEffects category:

// A description of how to compute the box kernel width from the Gaussian
// radius (aka standard deviation) appears in the SVG spec:
// http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
//
// For larger values of 's' (s >= 2.0), an approximation can be used: Three
// successive box-blurs build a piece-wise quadratic convolution kernel, which
// approximates the Gaussian kernel to within roughly 3%.
//
// let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
//
// ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.


- (void)setBlurRadiusInPixels:(CGFloat)newValue;
{
    blurFilter.blurRadiusInPixels = newValue;
}

- (CGFloat)blurRadiusInPixels;
{
    return blurFilter.blurRadiusInPixels;
}

- (void)setSaturation:(CGFloat)newValue;
{
    saturationFilter.saturation = newValue;
}

- (CGFloat)saturation;
{
    return saturationFilter.saturation;
}

- (void)setDownsampling:(CGFloat)newValue;
{
    _downsampling = newValue;
}

- (void)setRangeReductionFactor:(CGFloat)rangeReductionFactor
{
    luminanceRangeFilter.rangeReductionFactor = rangeReductionFactor;
}

- (CGFloat)rangeReductionFactor
{
    return luminanceRangeFilter.rangeReductionFactor;
}

@end

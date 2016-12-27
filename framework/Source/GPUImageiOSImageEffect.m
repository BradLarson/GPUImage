#import "GPUImageiOSImageEffect.h"
#import "GPUImageSaturationFilter.h"
#import "GPUImageGaussianBlurFilter.h"
#import "GPUImageSolidColorGenerator.h"
#import "GPUImageAlphaBlendFilter.h"

@implementation GPUImageiOSImageEffect

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

    colorGenerator = [[GPUImageSolidColorGenerator alloc] init];
    [self addFilter:colorGenerator];

    blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    [self addFilter:blendFilter];

    [saturationFilter addTarget:blurFilter];
    [blurFilter addTarget:blendFilter];
    [colorGenerator addTarget:blendFilter];

    self.initialFilters = @[saturationFilter];
    self.terminalFilter = blendFilter;

    self.blurRadiusInPixels = 12.0;
    self.saturation = 1.8;
    self.downsampling = 4.0;
    self.effectType = GPUImageIOSImageEffectTypeLight;

    return self;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    if (_downsampling > 1.0)
    {
        CGSize rotatedSize = [saturationFilter rotatedSize:newSize forIndex:textureIndex];

        [saturationFilter forceProcessingAtSize:CGSizeMake(rotatedSize.width / _downsampling, rotatedSize.height / _downsampling)];
        [colorGenerator forceProcessingAtSize:rotatedSize];
        [blendFilter forceProcessingAtSize:rotatedSize];
    }

    [super setInputSize:newSize atIndex:textureIndex];
}

#pragma mark -
#pragma mark Accessors

- (void)setEffectType:(GPUImageIOSImageEffectType)effectType
{
    _effectType = effectType;
    switch (effectType) {
        case GPUImageIOSImageEffectTypeLight:
            [colorGenerator setColorRed:1 green:1 blue:1 alpha:1];
            blendFilter.mix = 0.3;
            break;
        case GPUImageIOSImageEffectTypeExtraLight:
            [colorGenerator setColorRed:0.97 green:0.97 blue:0.97 alpha:1];
            blendFilter.mix = 0.82;
            break;
        case GPUImageIOSImageEffectTypeDark:
            [colorGenerator setColorRed:0.11 green:0.11 blue:0.11 alpha:1];
            blendFilter.mix = 0.73;
            break;
    }
}

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

@end
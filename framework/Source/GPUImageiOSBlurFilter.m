#import "GPUImageiOSBlurFilter.h"
#import "GPUImageSaturationFilter.h"
#import "GPUImageGaussianBlurFilter.h"
#import "GPUImageGammaFilter.h"

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
    
    // Third pass: upsample and adjust gamma
    gammaFilter = [[GPUImageGammaFilter alloc] init];
    [self addFilter:gammaFilter];
        
    [saturationFilter addTarget:blurFilter];
    [blurFilter addTarget:gammaFilter];
    
    self.initialFilters = [NSArray arrayWithObject:saturationFilter];
    //    self.terminalFilter = nonMaximumSuppressionFilter;
    self.terminalFilter = gammaFilter;
    
    self.blurRadiusInPixels = 24.0;
    self.saturation = 0.6;
    self.downsampling = 2.0;

    return self;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    if (_downsampling > 1.0)
    {
        CGSize rotatedSize = [saturationFilter rotatedSize:newSize forIndex:textureIndex];

        [saturationFilter forceProcessingAtSize:CGSizeMake(rotatedSize.width / _downsampling, rotatedSize.height / _downsampling)];
        [gammaFilter forceProcessingAtSize:rotatedSize];
    }
    
    [super setInputSize:newSize atIndex:textureIndex];
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

#import "GPUImageFilterGroup.h"

@class GPUImageGaussianBlurFilter;

/// A simulated tilt shift lens effect
@interface GPUImageTiltShiftFilter : GPUImageFilterGroup
{
    GPUImageGaussianBlurFilter *blurFilter;
    GPUImageFilter *tiltShiftFilter;
}

/// A multiplier for the underlying blur size, ranging from 0.0 on up, with a default of 2.0
@property(readwrite, nonatomic) CGFloat blurSize;

/// The normalized location of the top of the in-focus area in the image, this value should be lower than bottomFocusLevel, default 0.4
@property(readwrite, nonatomic) CGFloat topFocusLevel;

/// The normalized location of the bottom of the in-focus area in the image, this value should be higher than topFocusLevel, default 0.6
@property(readwrite, nonatomic) CGFloat bottomFocusLevel; 

/// The rate at which the image gets blurry away from the in-focus region, default 0.2
@property(readwrite, nonatomic) CGFloat focusFallOffRate; 

@end

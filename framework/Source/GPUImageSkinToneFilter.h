//
//  GPUImageSkinToneFilter.h
//
//
//  Created by github.com/r3mus on 8/14/15.
//
//

#import "GPUImageTwoInputFilter.h"

typedef NS_ENUM(NSUInteger, GPUImageSkinToneUpperColor) {
    GPUImageSkinToneUpperColorGreen,
    GPUImageSkinToneUpperColorOrange
};

extern NSString *const kGPUImageSkinToneFragmentShaderString;

@interface GPUImageSkinToneFilter : GPUImageFilter
{
    GLint skinToneAdjustUniform;
    GLint skinHueUniform;
    GLint skinHueThresholdUniform;
    GLint maxHueShiftUniform;
    GLint maxSaturationShiftUniform;
    GLint upperSkinToneColorUniform;
}

// The amount of effect to apply, between -1.0 (pink) and +1.0 (orange OR green). Default is 0.0.
@property (nonatomic, readwrite) CGFloat skinToneAdjust;

// The initial hue of skin to adjust. Default is 0.05 (a common skin red).
@property (nonatomic, readwrite) CGFloat skinHue;

// The bell curve "breadth" of the skin hue adjustment (i.e. how different from the original skinHue will the modifications effect).
// Default is 40.0
@property (nonatomic, readwrite) CGFloat skinHueThreshold;

// The maximum amount of hue shift allowed in the adjustments that affect hue (pink, green). Default = 0.25.
@property (nonatomic, readwrite) CGFloat maxHueShift;

// The maximum amount of saturation shift allowed in the adjustments that affect saturation (orange). Default = 0.4.
@property (nonatomic, readwrite) CGFloat maxSaturationShift;

// Defines whether the upper range (> 0.0) will change the skin tone to green (hue) or orange (saturation)
@property (nonatomic, readwrite) GPUImageSkinToneUpperColor upperSkinToneColor;

@end

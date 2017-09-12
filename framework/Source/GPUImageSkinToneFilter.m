//
//  GPUImageSkinToneFilter.m
//
//
//  Created by github.com/r3mus on 8/13/15.
//
//

#import "GPUImageSkinToneFilter.h"

@implementation GPUImageSkinToneFilter

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageSkinToneFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 // [-1;1] <=> [pink;orange]
 uniform highp float skinToneAdjust; // will make reds more pink
 
 // Other parameters
 uniform mediump float skinHue;
 uniform mediump float skinHueThreshold;
 uniform mediump float maxHueShift;
 uniform mediump float maxSaturationShift;
 uniform int upperSkinToneColor;
 
 // RGB <-> HSV conversion, thanks to http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
 highp vec3 rgb2hsv(highp vec3 c)
{
    highp vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    highp vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    highp vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    
    highp float d = q.x - min(q.w, q.y);
    highp float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
 
 // HSV <-> RGB conversion, thanks to http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
 highp vec3 hsv2rgb(highp vec3 c)
{
    highp vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    highp vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
 
 // Main
 void main ()
{
    
    // Sample the input pixel
    highp vec4 colorRGB = texture2D(inputImageTexture, textureCoordinate);
    
    // Convert color to HSV, extract hue
    highp vec3 colorHSV = rgb2hsv(colorRGB.rgb);
    highp float hue = colorHSV.x;
    
    // check how far from skin hue
    highp float dist = hue - skinHue;
    if (dist > 0.5)
        dist -= 1.0;
    if (dist < -0.5)
        dist += 1.0;
    dist = abs(dist)/0.5; // normalized to [0,1]
    
    // Apply Gaussian like filter
    highp float weight = exp(-dist*dist*skinHueThreshold);
    weight = clamp(weight, 0.0, 1.0);
    
    // Using pink/green, so only adjust hue
    if (upperSkinToneColor == 0) {
        colorHSV.x += skinToneAdjust * weight * maxHueShift;
    // Using pink/orange, so adjust hue < 0 and saturation > 0
    } else if (upperSkinToneColor == 1) {
        // We want more orange, so increase saturation
        if (skinToneAdjust > 0.0)
            colorHSV.y += skinToneAdjust * weight * maxSaturationShift;
        // we want more pinks, so decrease hue
        else
            colorHSV.x += skinToneAdjust * weight * maxHueShift;
    }

    // final color
    highp vec3 finalColorRGB = hsv2rgb(colorHSV.rgb);
    
    // display
    gl_FragColor = vec4(finalColorRGB, 1.0);
}
);
#else
NSString *const kGPUImageSkinToneFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 // [-1;1] <=> [pink;orange]
 uniform float skinToneAdjust; // will make reds more pink
 
 // Other parameters
 uniform float skinHue;
 uniform float skinHueThreshold;
 uniform float maxHueShift;
 uniform float maxSaturationShift;
 uniform int upperSkinToneColor;
 
 // RGB <-> HSV conversion, thanks to http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
 highp vec3 rgb2hsv(highp vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
 
 // HSV <-> RGB conversion, thanks to http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
 highp vec3 hsv2rgb(highp vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
 
 // Main
 void main ()
{
    
    // Sample the input pixel
    vec4 colorRGB = texture2D(inputImageTexture, textureCoordinate);
    
    // Convert color to HSV, extract hue
    vec3 colorHSV = rgb2hsv(colorRGB.rgb);
    float hue = colorHSV.x;
    
    // check how far from skin hue
    float dist = hue - skinHue;
    if (dist > 0.5)
        dist -= 1.0;
    if (dist < -0.5)
        dist += 1.0;
    dist = abs(dist)/0.5; // normalized to [0,1]
    
    // Apply Gaussian like filter
    float weight = exp(-dist*dist*skinHueThreshold);
    weight = clamp(weight, 0.0, 1.0);
    
    // Using pink/green, so only adjust hue
    if (upperSkinToneColor == 0) {
        colorHSV.x += skinToneAdjust * weight * maxHueShift;
        // Using pink/orange, so adjust hue < 0 and saturation > 0
    } else if (upperSkinToneColor == 1) {
        // We want more orange, so increase saturation
        if (skinToneAdjust > 0.0)
            colorHSV.y += skinToneAdjust * weight * maxSaturationShift;
        // we want more pinks, so decrease hue
        else
            colorHSV.x += skinToneAdjust * weight * maxHueShift;
    }
    
    // final color
    vec3 finalColorRGB = hsv2rgb(colorHSV.rgb);
    
    // display
    gl_FragColor = vec4(finalColorRGB, 1.0);
}
 );
#endif

#pragma mark -
#pragma mark Initialization and teardown
@synthesize skinToneAdjust;
@synthesize skinHue;
@synthesize skinHueThreshold;
@synthesize maxHueShift;
@synthesize maxSaturationShift;
@synthesize upperSkinToneColor;

- (id)init
{
    if(! (self = [super initWithFragmentShaderFromString:kGPUImageSkinToneFragmentShaderString]) )
    {
        return nil;
    }
    
    skinToneAdjustUniform = [filterProgram uniformIndex:@"skinToneAdjust"];
    skinHueUniform = [filterProgram uniformIndex:@"skinHue"];
    skinHueThresholdUniform = [filterProgram uniformIndex:@"skinHueThreshold"];
    maxHueShiftUniform = [filterProgram uniformIndex:@"maxHueShift"];
    maxSaturationShiftUniform = [filterProgram uniformIndex:@"maxSaturationShift"];
    upperSkinToneColorUniform = [filterProgram uniformIndex:@"upperSkinToneColor"];
    
    self.skinHue = 0.05;
    self.skinHueThreshold = 40.0;
    self.maxHueShift = 0.25;
    self.maxSaturationShift = 0.4;
    self.upperSkinToneColor = GPUImageSkinToneUpperColorGreen;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setSkinToneAdjust:(CGFloat)newValue
{
    skinToneAdjust = newValue;
    [self setFloat:newValue forUniform:skinToneAdjustUniform program:filterProgram];
}

- (void)setSkinHue:(CGFloat)newValue
{
    skinHue = newValue;
    [self setFloat:newValue forUniform:skinHueUniform program:filterProgram];
}

- (void)setSkinHueThreshold:(CGFloat)newValue
{
    skinHueThreshold = newValue;
    [self setFloat:newValue forUniform:skinHueThresholdUniform program:filterProgram];
}

- (void)setMaxHueShift:(CGFloat)newValue
{
    maxHueShift = newValue;
    [self setFloat:newValue forUniform:maxHueShiftUniform program:filterProgram];
}

- (void)setMaxSaturationShift:(CGFloat)newValue
{
    maxSaturationShift = newValue;
    [self setFloat:newValue forUniform:maxSaturationShiftUniform program:filterProgram];
}

- (void)setUpperSkinToneColor:(GPUImageSkinToneUpperColor)newValue
{
    upperSkinToneColor = newValue;
    [self setInteger:newValue forUniform:upperSkinToneColorUniform program:filterProgram];
}

@end
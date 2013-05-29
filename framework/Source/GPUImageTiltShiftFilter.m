#import "GPUImageTiltShiftFilter.h"
#import "GPUImageFilter.h"
#import "GPUImageTwoInputFilter.h"
#import "GPUImageGaussianBlurFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageTiltShiftFragmentShaderString = SHADER_STRING
( 
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; 
 
 uniform highp float topFocusLevel;
 uniform highp float bottomFocusLevel;
 uniform highp float focusFallOffRate;
 
 void main()
 {
     lowp vec4 sharpImageColor = texture2D(inputImageTexture, textureCoordinate);
     lowp vec4 blurredImageColor = texture2D(inputImageTexture2, textureCoordinate2);
     
     lowp float blurIntensity = 1.0 - smoothstep(topFocusLevel - focusFallOffRate, topFocusLevel, textureCoordinate2.y);
     blurIntensity += smoothstep(bottomFocusLevel, bottomFocusLevel + focusFallOffRate, textureCoordinate2.y);
     
     gl_FragColor = mix(sharpImageColor, blurredImageColor, blurIntensity);
 }
);
#else
NSString *const kGPUImageTiltShiftFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform float topFocusLevel;
 uniform float bottomFocusLevel;
 uniform float focusFallOffRate;
 
 void main()
 {
     vec4 sharpImageColor = texture2D(inputImageTexture, textureCoordinate);
     vec4 blurredImageColor = texture2D(inputImageTexture2, textureCoordinate2);
     
     float blurIntensity = 1.0 - smoothstep(topFocusLevel - focusFallOffRate, topFocusLevel, textureCoordinate2.y);
     blurIntensity += smoothstep(bottomFocusLevel, bottomFocusLevel + focusFallOffRate, textureCoordinate2.y);
     
     gl_FragColor = mix(sharpImageColor, blurredImageColor, blurIntensity);
 }
);
#endif

@implementation GPUImageTiltShiftFilter

@synthesize blurSize;
@synthesize topFocusLevel = _topFocusLevel;
@synthesize bottomFocusLevel = _bottomFocusLevel;
@synthesize focusFallOffRate = _focusFallOffRate;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    // First pass: apply a variable Gaussian blur
    blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
    [self addFilter:blurFilter];
        
    // Second pass: combine the blurred image with the original sharp one
    tiltShiftFilter = [[GPUImageTwoInputFilter alloc] initWithFragmentShaderFromString:kGPUImageTiltShiftFragmentShaderString];
    [self addFilter:tiltShiftFilter];
    
    // Texture location 0 needs to be the sharp image for both the blur and the second stage processing
    [blurFilter addTarget:tiltShiftFilter atTextureLocation:1];
    
    // To prevent double updating of this filter, disable updates from the sharp image side
//    self.inputFilterToIgnoreForUpdates = tiltShiftFilter;
    
    self.initialFilters = [NSArray arrayWithObjects:blurFilter, tiltShiftFilter, nil];
    self.terminalFilter = tiltShiftFilter;
    
    self.topFocusLevel = 0.4;
    self.bottomFocusLevel = 0.6;
    self.focusFallOffRate = 0.2;
    self.blurSize = 2.0;
    
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

- (void)setTopFocusLevel:(CGFloat)newValue;
{
    _topFocusLevel = newValue;
    [tiltShiftFilter setFloat:newValue forUniformName:@"topFocusLevel"];
}

- (void)setBottomFocusLevel:(CGFloat)newValue;
{
    _bottomFocusLevel = newValue;
    [tiltShiftFilter setFloat:newValue forUniformName:@"bottomFocusLevel"];
}

- (void)setFocusFallOffRate:(CGFloat)newValue;
{
    _focusFallOffRate = newValue;
    [tiltShiftFilter setFloat:newValue forUniformName:@"focusFallOffRate"];
}

@end
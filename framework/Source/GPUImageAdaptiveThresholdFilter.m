#import "GPUImageAdaptiveThresholdFilter.h"
#import "GPUImageFilter.h"
#import "GPUImageTwoInputFilter.h"
#import "GPUImageGrayscaleFilter.h"
#import "GPUImageBoxBlurFilter.h"

NSString *const kGPUImageAdaptiveThresholdFragmentShaderString = SHADER_STRING
( 
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; 
 
 void main()
 {
     highp float blurredInput = texture2D(inputImageTexture, textureCoordinate).r;
     highp float localLuminance = texture2D(inputImageTexture2, textureCoordinate2).r;
     highp float thresholdResult = step(blurredInput - 0.05, localLuminance);
     
     gl_FragColor = vec4(vec3(thresholdResult), 1.0);
//     gl_FragColor = vec4(localLuminance, textureColor.r, 0.0, textureColor.w);
//     gl_FragColor = vec4(localLuminance, localLuminance, localLuminance, 1.0);
 }
 );

@interface GPUImageAdaptiveThresholdFilter()
{
    GPUImageBoxBlurFilter *boxBlurFilter;
}
@end

@implementation GPUImageAdaptiveThresholdFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    // First pass: reduce to luminance
    GPUImageGrayscaleFilter *luminanceFilter = [[GPUImageGrayscaleFilter alloc] init];
    [self addFilter:luminanceFilter];
    
    // Second pass: perform a box blur
    boxBlurFilter = [[GPUImageBoxBlurFilter alloc] init];
    [self addFilter:boxBlurFilter];
    
    // Third pass: compare the blurred background luminance to the local value
    GPUImageFilter *adaptiveThresholdFilter = [[GPUImageTwoInputFilter alloc] initWithFragmentShaderFromString:kGPUImageAdaptiveThresholdFragmentShaderString];
    [self addFilter:adaptiveThresholdFilter];
    
    [luminanceFilter addTarget:boxBlurFilter];
    
    [boxBlurFilter addTarget:adaptiveThresholdFilter];
    // To prevent double updating of this filter, disable updates from the sharp luminance image side
    [luminanceFilter addTarget:adaptiveThresholdFilter];
    
    self.initialFilters = [NSArray arrayWithObject:luminanceFilter];
    self.terminalFilter = adaptiveThresholdFilter;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setBlurSize:(CGFloat)newValue;
{
    boxBlurFilter.blurSize = newValue;
}

- (CGFloat)blurSize;
{
    return boxBlurFilter.blurSize;
}

@end

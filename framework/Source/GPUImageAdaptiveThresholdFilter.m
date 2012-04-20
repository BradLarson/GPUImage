#import "GPUImageAdaptiveThresholdFilter.h"
#import "GPUImageFilter.h"
#import "GPUImageGrayscaleFilter.h"
#import "GPUImageBoxBlurFilter.h"

NSString *const kGPUImageAdaptiveThresholdFragmentShaderString = SHADER_STRING
( 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; 
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     highp float localLuminance = texture2D(inputImageTexture2, textureCoordinate).r;
     highp float thresholdResult = step(localLuminance - 0.05, textureColor.r);
     
     gl_FragColor = vec4(vec3(thresholdResult), textureColor.w);
//     gl_FragColor = vec4(localLuminance, textureColor.r, 0.0, textureColor.w);
 }
 );

@implementation GPUImageAdaptiveThresholdFilter

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
    GPUImageBoxBlurFilter *boxBlurFilter = [[GPUImageBoxBlurFilter alloc] init];
    [self addFilter:boxBlurFilter];
    
    // Third pass: compare the blurred background luminance to the local value
    GPUImageFilter *adaptiveThresholdFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromString:kGPUImageAdaptiveThresholdFragmentShaderString];
    [self addFilter:adaptiveThresholdFilter];
    
    [luminanceFilter addTarget:boxBlurFilter];
    
    [boxBlurFilter addTarget:adaptiveThresholdFilter];
    // To prevent double updating of this filter, disable updates from the sharp luminance image side
    adaptiveThresholdFilter.shouldIgnoreUpdatesToThisTarget = YES;
    [luminanceFilter addTarget:adaptiveThresholdFilter];
    
    self.initialFilters = [NSArray arrayWithObject:luminanceFilter];
    self.terminalFilter = adaptiveThresholdFilter;
    
    return self;
}

@end

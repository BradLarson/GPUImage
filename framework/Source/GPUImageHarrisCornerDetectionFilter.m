#import "GPUImageHarrisCornerDetectionFilter.h"
#import "GPUImageFilter.h"
#import "GPUImageGaussianBlurFilter.h"
#import "GPUImageXYDerivativeFilter.h"
#import "GPUImageGrayscaleFilter.h"
#import "GPUImageFastBlurFilter.h"

// This is the Harris corner detector, as described in 
// C. Harris and M. Stephens. A Combined Corner and Edge Detector. Proc. Alvey Vision Conf., Univ. Manchester, pp. 147-151, 1988.

@implementation GPUImageHarrisCornerDetectionFilter

NSString *const kGPUImageHarrisCornerDetectionFragmentShaderString = SHADER_STRING
( 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 const mediump float harrisConstant = 0.01;
 
 void main()
 {
     mediump vec3 derivativeElements = texture2D(inputImageTexture, textureCoordinate).rgb;
     
     mediump float derivativeSum = derivativeElements.x + derivativeElements.y;
     
     // This is the Noble variant on the Harris detector, from 
     // Alison Noble, "Descriptions of Image Surfaces", PhD thesis, Department of Engineering Science, Oxford University 1989, p45.     
     mediump float harrisIntensity = (derivativeElements.x * derivativeElements.y - (derivativeElements.z * derivativeElements.z)) / (derivativeSum);

     // Original Harris detector
//     highp float harrisIntensity = derivativeElements.x * derivativeElements.y - (derivativeElements.z * derivativeElements.z) - harrisConstant * derivativeSum * derivativeSum;
     
     gl_FragColor = vec4(vec3(harrisIntensity * 8.0), 1.0);
 }
);

NSString *const kGPUImageSimpleThresholdFragmentShaderString = SHADER_STRING
( 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 const lowp float threshold = 0.2;
 
 void main()
 {
     lowp float intensity = texture2D(inputImageTexture, textureCoordinate).r;

     lowp float thresholdValue = step(threshold, intensity);
     
     gl_FragColor = vec4(thresholdValue, 0.0, 0.0, thresholdValue);
 }
 );

@synthesize blurSize;
//@synthesize intensity = _intensity;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    // First pass: reduce to luminance
    luminanceFilter = [[GPUImageGrayscaleFilter alloc] init];
    [self addFilter:luminanceFilter];
    
    // Second pass: take the derivative of the luminance texture
    derivativeFilter = [[GPUImageXYDerivativeFilter alloc] init];
    derivativeFilter.imageWidthFactor = 256.0;
    derivativeFilter.imageHeightFactor = 256.0;
    [self addFilter:derivativeFilter];
    
    // Third pass: blur the derivative
//    blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
    blurFilter = [[GPUImageFastBlurFilter alloc] init];
    [self addFilter:blurFilter];
    
    // Fourth pass: apply the Harris corner detection calculation
    harrisCornerDetectionFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromString:kGPUImageHarrisCornerDetectionFragmentShaderString];
    [self addFilter:harrisCornerDetectionFilter];
    
    // TODO: Non-maximum suppression filter here
    
    // Fifth pass: threshold the result
    simpleThresholdFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromString:kGPUImageSimpleThresholdFragmentShaderString];
    [self addFilter:simpleThresholdFilter];
    
    [luminanceFilter addTarget:derivativeFilter];
    [derivativeFilter addTarget:blurFilter];    
    [blurFilter addTarget:harrisCornerDetectionFilter];
    [harrisCornerDetectionFilter addTarget:simpleThresholdFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:luminanceFilter, nil];
//    self.terminalFilter = harrisCornerDetectionFilter;
    self.terminalFilter = simpleThresholdFilter;
    
//    self.intensity = 1.0;
    self.blurSize = 1.5;
    
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

//- (void)setIntensity:(CGFloat)newValue;
//{
//    _intensity = newValue;
//    [unsharpMaskFilter setFloat:newValue forUniform:@"intensity"];
//}

@end

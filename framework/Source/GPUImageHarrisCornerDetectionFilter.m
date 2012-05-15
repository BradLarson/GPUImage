#import "GPUImageHarrisCornerDetectionFilter.h"
#import "GPUImageFilter.h"
#import "GPUImageGaussianBlurFilter.h"
#import "GPUImageXYDerivativeFilter.h"
#import "GPUImageGrayscaleFilter.h"
#import "GPUImageFastBlurFilter.h"
#import "GPUImageNonMaximumSuppressionFilter.h"

@interface GPUImageHarrisCornerDetectionFilter()

- (void)extractCornerLocationsFromImage;

@end

// This is the Harris corner detector, as described in 
// C. Harris and M. Stephens. A Combined Corner and Edge Detector. Proc. Alvey Vision Conf., Univ. Manchester, pp. 147-151, 1988.

@implementation GPUImageHarrisCornerDetectionFilter

NSString *const kGPUImageHarrisCornerDetectionFragmentShaderString = SHADER_STRING
( 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 const mediump float harrisConstant = 0.04;
 
 void main()
 {
     mediump vec3 derivativeElements = texture2D(inputImageTexture, textureCoordinate).rgb;
     
     mediump float derivativeSum = derivativeElements.x + derivativeElements.y;
     
     // This is the Noble variant on the Harris detector, from 
     // Alison Noble, "Descriptions of Image Surfaces", PhD thesis, Department of Engineering Science, Oxford University 1989, p45.     
     mediump float harrisIntensity = (derivativeElements.x * derivativeElements.y - (derivativeElements.z * derivativeElements.z)) / (derivativeSum);

     // Original Harris detector
//     highp float harrisIntensity = derivativeElements.x * derivativeElements.y - (derivativeElements.z * derivativeElements.z) - harrisConstant * derivativeSum * derivativeSum;
     
     gl_FragColor = vec4(vec3(harrisIntensity * 7.0), 1.0);
 }
);

NSString *const kGPUImageSimpleThresholdFragmentShaderString = SHADER_STRING
( 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 const lowp float threshold = 0.50;
 
 void main()
 {
     lowp float intensity = texture2D(inputImageTexture, textureCoordinate).r;

     lowp float thresholdValue = step(threshold, intensity);
     
     gl_FragColor = vec4(thresholdValue, 0.0, 0.0, thresholdValue);
//     gl_FragColor = vec4(intensity, intensity, intensity, 1.0);
//     gl_FragColor = vec4(intensity, 0.0, 0.0, intensity);
 }
 );

@synthesize blurSize;
@synthesize cornersDetectedBlock;

//@synthesize intensity = _intensity;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }

//    preblurFilter = [[GPUImageFastBlurFilter alloc] init];
//    [self addFilter:preblurFilter];

    // First pass: reduce to luminance and take the derivative of the luminance texture
    derivativeFilter = [[GPUImageXYDerivativeFilter alloc] init];
//    derivativeFilter.imageWidthFactor = 256.0;
//    derivativeFilter.imageHeightFactor = 256.0;
    [self addFilter:derivativeFilter];
    
    // Second pass: blur the derivative
//    blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
    blurFilter = [[GPUImageFastBlurFilter alloc] init];
    [self addFilter:blurFilter];
    
    // Third pass: apply the Harris corner detection calculation
    harrisCornerDetectionFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromString:kGPUImageHarrisCornerDetectionFragmentShaderString];
    [self addFilter:harrisCornerDetectionFilter];
    
    // Fourth pass: apply non-maximum suppression to find the local maxima
    nonMaximumSuppressionFilter = [[GPUImageNonMaximumSuppressionFilter alloc] init];
    [self addFilter:nonMaximumSuppressionFilter];
    
    // Fifth pass: threshold the result
    simpleThresholdFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromString:kGPUImageSimpleThresholdFragmentShaderString];
    [self addFilter:simpleThresholdFilter];
    
    __unsafe_unretained GPUImageHarrisCornerDetectionFilter *weakSelf = self;
    
    [simpleThresholdFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter) {
        NSLog(@"Frame processing completed for filter: %@", filter);
        [weakSelf extractCornerLocationsFromImage];
    }];
    
//    [preblurFilter addTarget:luminanceFilter];
    [derivativeFilter addTarget:blurFilter];    
    [blurFilter addTarget:harrisCornerDetectionFilter];
    [harrisCornerDetectionFilter addTarget:nonMaximumSuppressionFilter];
    [nonMaximumSuppressionFilter addTarget:simpleThresholdFilter];
//    [harrisCornerDetectionFilter addTarget:simpleThresholdFilter];
    
//    self.initialFilters = [NSArray arrayWithObjects:preblurFilter, nil];
    self.initialFilters = [NSArray arrayWithObjects:derivativeFilter, nil];
//    self.terminalFilter = nonMaximumSuppressionFilter;
//    self.terminalFilter = harrisCornerDetectionFilter;
    self.terminalFilter = simpleThresholdFilter;
    
//    self.intensity = 1.0;
    self.blurSize = 1.0;
    
    return self;
}
     
#pragma mark -
#pragma mark Corner extraction

- (void)extractCornerLocationsFromImage;
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

    GLfloat *cornersArray;
    NSUInteger numberOfCorners = 0;
    CGSize imageSize = simpleThresholdFilter.outputFrameSize;
    
    GLubyte *rawImagePixels = (GLubyte *)malloc(imageSize.width * imageSize.height * 4);
    cornersArray = calloc(256 * 2, sizeof(GLfloat));
    
    glReadPixels(0, 0, (int)imageSize.width, (int)imageSize.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);

    for (unsigned int yCoordinate = 0; yCoordinate < imageSize.height; yCoordinate++)
    {
        for (unsigned int xCoordinate = 0; xCoordinate < imageSize.width; xCoordinate++)
        {
            GLubyte redByte = rawImagePixels[(yCoordinate * (int)imageSize.width + xCoordinate) * 4];
            if (redByte > 100)
            {
                cornersArray[numberOfCorners * 2] = (CGFloat)xCoordinate / imageSize.width;
                cornersArray[numberOfCorners * 2 + 1] = (CGFloat)yCoordinate / imageSize.height;
                numberOfCorners++;
            }
        }
    }
    
    free(rawImagePixels);
    
    CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
    NSLog(@"Processing time : %f ms", 1000.0 * currentFrameTime);

    if (cornersDetectedBlock != NULL)
    {
        cornersDetectedBlock(cornersArray, numberOfCorners);
    }
    
    free(cornersArray);
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

#import "GPUImageHarrisCornerDetectionFilter.h"
#import "GPUImageGaussianBlurFilter.h"
#import "GPUImageXYDerivativeFilter.h"
#import "GPUImageGrayscaleFilter.h"
#import "GPUImageFastBlurFilter.h"
#import "GPUImageThresholdedNonMaximumSuppressionFilter.h"
#import "GPUImageColorPackingFilter.h"

@interface GPUImageHarrisCornerDetectionFilter()

- (void)extractCornerLocationsFromImageAtFrameTime:(CMTime)frameTime;

@end

// This is the Harris corner detector, as described in 
// C. Harris and M. Stephens. A Combined Corner and Edge Detector. Proc. Alvey Vision Conf., Univ. Manchester, pp. 147-151, 1988.

@implementation GPUImageHarrisCornerDetectionFilter

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageHarrisCornerDetectionFragmentShaderString = SHADER_STRING
( 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float sensitivity;
 
 const mediump float harrisConstant = 0.04;
 
 void main()
 {
     mediump vec3 derivativeElements = texture2D(inputImageTexture, textureCoordinate).rgb;
     
     mediump float derivativeSum = derivativeElements.x + derivativeElements.y;
     
     mediump float zElement = (derivativeElements.z * 2.0) - 1.0;

     // R = Ix^2 * Iy^2 - Ixy * Ixy - k * (Ix^2 + Iy^2)^2
     mediump float cornerness = derivativeElements.x * derivativeElements.y - (zElement * zElement) - harrisConstant * derivativeSum * derivativeSum;
     
     gl_FragColor = vec4(vec3(cornerness * sensitivity), 1.0);
 }
);
#else
NSString *const kGPUImageHarrisCornerDetectionFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float sensitivity;
 
 const float harrisConstant = 0.04;
 
 void main()
 {
     vec3 derivativeElements = texture2D(inputImageTexture, textureCoordinate).rgb;
     
     float derivativeSum = derivativeElements.x + derivativeElements.y;
     
     float zElement = (derivativeElements.z * 2.0) - 1.0;
     
     // R = Ix^2 * Iy^2 - Ixy * Ixy - k * (Ix^2 + Iy^2)^2
     float cornerness = derivativeElements.x * derivativeElements.y - (zElement * zElement) - harrisConstant * derivativeSum * derivativeSum;
     
     gl_FragColor = vec4(vec3(cornerness * sensitivity), 1.0);
 }
);
#endif

@synthesize blurSize;
@synthesize cornersDetectedBlock;
@synthesize sensitivity = _sensitivity;
@synthesize threshold = _threshold;
@synthesize intermediateImages = _intermediateImages;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithCornerDetectionFragmentShader:kGPUImageHarrisCornerDetectionFragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

- (id)initWithCornerDetectionFragmentShader:(NSString *)cornerDetectionFragmentShader;
{
    if (!(self = [super init]))
    {
		return nil;
    }

#ifdef DEBUGFEATUREDETECTION
    _intermediateImages = [[NSMutableArray alloc] init];
#endif
    
    // First pass: reduce to luminance and take the derivative of the luminance texture
    derivativeFilter = [[GPUImageXYDerivativeFilter alloc] init];
    [self addFilter:derivativeFilter];

#ifdef DEBUGFEATUREDETECTION
    __unsafe_unretained NSMutableArray *weakIntermediateImages = _intermediateImages;
    __unsafe_unretained GPUImageFilter *weakFilter = derivativeFilter;
    [derivativeFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime){
        UIImage *intermediateImage = [weakFilter imageFromCurrentlyProcessedOutput];
        [weakIntermediateImages addObject:intermediateImage];
    }];
#endif

    // Second pass: blur the derivative
    blurFilter = [[GPUImageFastBlurFilter alloc] init];
    [self addFilter:blurFilter];
    
#ifdef DEBUGFEATUREDETECTION
    weakFilter = blurFilter;
    [blurFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime){
        UIImage *intermediateImage = [weakFilter imageFromCurrentlyProcessedOutput];
        [weakIntermediateImages addObject:intermediateImage];
    }];
#endif
    
    // Third pass: apply the Harris corner detection calculation
    harrisCornerDetectionFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromString:cornerDetectionFragmentShader];
    [self addFilter:harrisCornerDetectionFilter];

#ifdef DEBUGFEATUREDETECTION
    weakFilter = harrisCornerDetectionFilter;
    [harrisCornerDetectionFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime){
        UIImage *intermediateImage = [weakFilter imageFromCurrentlyProcessedOutput];
        [weakIntermediateImages addObject:intermediateImage];
    }];
#endif

    // Fourth pass: apply non-maximum suppression and thresholding to find the local maxima
    nonMaximumSuppressionFilter = [[GPUImageThresholdedNonMaximumSuppressionFilter alloc] init];
    [self addFilter:nonMaximumSuppressionFilter];

    __unsafe_unretained GPUImageHarrisCornerDetectionFilter *weakSelf = self;
#ifdef DEBUGFEATUREDETECTION
    weakFilter = nonMaximumSuppressionFilter;
    [nonMaximumSuppressionFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime){
        UIImage *intermediateImage = [weakFilter imageFromCurrentlyProcessedOutput];
        [weakIntermediateImages addObject:intermediateImage];
        
        [weakSelf extractCornerLocationsFromImageAtFrameTime:frameTime];
    }];
#else
    [nonMaximumSuppressionFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime) {
        [weakSelf extractCornerLocationsFromImageAtFrameTime:frameTime];
    }];
#endif
    
// Sixth pass: compress the thresholded points into the RGBA channels
//    colorPackingFilter = [[GPUImageColorPackingFilter alloc] init];
//    [self addFilter:colorPackingFilter];
//
//    
//#ifdef DEBUGFEATUREDETECTION
//    __unsafe_unretained GPUImageHarrisCornerDetectionFilter *weakSelf = self;
//    weakFilter = colorPackingFilter;
//    [colorPackingFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime){
//        NSLog(@"Triggered response from compaction filter");
//        
//        UIImage *intermediateImage = [weakFilter imageFromCurrentlyProcessedOutput];
//        [weakIntermediateImages addObject:intermediateImage];
//        
//        [weakSelf extractCornerLocationsFromImageAtFrameTime:frameTime];
//    }];
//#else
//    __unsafe_unretained GPUImageHarrisCornerDetectionFilter *weakSelf = self;
//    [colorPackingFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime) {
//        [weakSelf extractCornerLocationsFromImageAtFrameTime:frameTime];
//    }];
//#endif
    
    [derivativeFilter addTarget:blurFilter];    
    [blurFilter addTarget:harrisCornerDetectionFilter];
    [harrisCornerDetectionFilter addTarget:nonMaximumSuppressionFilter];
//    [simpleThresholdFilter addTarget:colorPackingFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:derivativeFilter, nil];
//    self.terminalFilter = colorPackingFilter;
    self.terminalFilter = nonMaximumSuppressionFilter;
    
    self.blurSize = 1.0;
    self.sensitivity = 5.0;
    self.threshold = 0.20;
    
    return self;
}
     
- (void)dealloc;
{
    free(rawImagePixels);
    free(cornersArray);
}

#pragma mark -
#pragma mark Corner extraction

- (void)extractCornerLocationsFromImageAtFrameTime:(CMTime)frameTime;
{
    // we need a normal color texture for this filter
    NSAssert(self.outputTextureOptions.internalFormat == GL_RGBA, @"The output texture format for this filter must be GL_RGBA.");
    NSAssert(self.outputTextureOptions.type == GL_UNSIGNED_BYTE, @"The type of the output texture of this filter must be GL_UNSIGNED_BYTE.");

    NSUInteger numberOfCorners = 0;
    CGSize imageSize = nonMaximumSuppressionFilter.outputFrameSize;
    
    unsigned int imageByteSize = imageSize.width * imageSize.height * 4;
    
    if (rawImagePixels == NULL)
    {
        rawImagePixels = (GLubyte *)malloc(imageByteSize);
        cornersArray = calloc(512 * 2, sizeof(GLfloat));
    }    
    
    glReadPixels(0, 0, (int)imageSize.width, (int)imageSize.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);

    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

    unsigned int imageWidth = imageSize.width * 4;
    
    unsigned int currentByte = 0;
    unsigned int cornerStorageIndex = 0;
    while (currentByte < imageByteSize)
    {
        GLubyte colorByte = rawImagePixels[currentByte];
        
        if (colorByte > 0)
        {
            unsigned int xCoordinate = currentByte % imageWidth;
            unsigned int yCoordinate = currentByte / imageWidth;
            
            cornersArray[cornerStorageIndex++] = (CGFloat)(xCoordinate / 4) / imageSize.width;
            cornersArray[cornerStorageIndex++] = (CGFloat)(yCoordinate) / imageSize.height;
            numberOfCorners++;
            
            numberOfCorners = MIN(numberOfCorners, 511);
            cornerStorageIndex = MIN(cornerStorageIndex, 1021);
        }
        currentByte +=4;
    }
    
    CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
    NSLog(@"Processing time : %f ms", 1000.0 * currentFrameTime);

    if (cornersDetectedBlock != NULL)
    {
        cornersDetectedBlock(cornersArray, numberOfCorners, frameTime);
    }
}

- (BOOL)wantsMonochromeInput;
{
    return YES;
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

- (void)setSensitivity:(CGFloat)newValue;
{
    _sensitivity = newValue;
    [harrisCornerDetectionFilter setFloat:newValue forUniformName:@"sensitivity"];
}

- (void)setThreshold:(CGFloat)newValue;
{
    nonMaximumSuppressionFilter.threshold = newValue;
}

- (CGFloat)threshold;
{
    return nonMaximumSuppressionFilter.threshold;
}

@end

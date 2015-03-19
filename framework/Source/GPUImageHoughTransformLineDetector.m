#import "GPUImageHoughTransformLineDetector.h"

@interface GPUImageHoughTransformLineDetector()

- (void)extractLineParametersFromImageAtFrameTime:(CMTime)frameTime;

@end

@implementation GPUImageHoughTransformLineDetector

@synthesize linesDetectedBlock;
@synthesize edgeThreshold;
@synthesize lineDetectionThreshold;
@synthesize intermediateImages = _intermediateImages;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    // First pass: do edge detection and threshold that to just have white pixels for edges
//    if ([GPUImageContext deviceSupportsFramebufferReads])
//    if ([GPUImageContext deviceSupportsFramebufferReads])
//    {
//        thresholdEdgeDetectionFilter = [[GPUImageThresholdEdgeDetectionFilter alloc] init];
//        thresholdEdgeDetectionFilter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
//        [(GPUImageThresholdEdgeDetectionFilter *)thresholdEdgeDetectionFilter setThreshold:0.07];
//        [(GPUImageThresholdEdgeDetectionFilter *)thresholdEdgeDetectionFilter setEdgeStrength:0.25];
//        [(GPUImageThresholdEdgeDetectionFilter *)thresholdEdgeDetectionFilter setEdgeStrength:1.0];
//        thresholdEdgeDetectionFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
//    }
//    else
//    {
        thresholdEdgeDetectionFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
//    }
    [self addFilter:thresholdEdgeDetectionFilter];
    
    // Second pass: extract the white points and draw representative lines in parallel coordinate space
    parallelCoordinateLineTransformFilter = [[GPUImageParallelCoordinateLineTransformFilter alloc] init];
    [self addFilter:parallelCoordinateLineTransformFilter];
    
    // Third pass: apply non-maximum suppression
    if ([GPUImageContext deviceSupportsFramebufferReads])
    {
        nonMaximumSuppressionFilter = [[GPUImageThresholdedNonMaximumSuppressionFilter alloc] initWithPackedColorspace:YES];
    }
    else
    {
        nonMaximumSuppressionFilter = [[GPUImageThresholdedNonMaximumSuppressionFilter alloc] initWithPackedColorspace:NO];
    }
    [self addFilter:nonMaximumSuppressionFilter];
    
    __unsafe_unretained GPUImageHoughTransformLineDetector *weakSelf = self;
#ifdef DEBUGLINEDETECTION
    _intermediateImages = [[NSMutableArray alloc] init];
    __unsafe_unretained NSMutableArray *weakIntermediateImages = _intermediateImages;

//    __unsafe_unretained GPUImageOutput<GPUImageInput> *weakEdgeDetectionFilter = thresholdEdgeDetectionFilter;
//    [thresholdEdgeDetectionFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime){
//        [weakIntermediateImages removeAllObjects];
//        UIImage *intermediateImage = [weakEdgeDetectionFilter imageFromCurrentFramebuffer];
//        [weakIntermediateImages addObject:intermediateImage];
//    }];
//
//    __unsafe_unretained GPUImageOutput<GPUImageInput> *weakParallelCoordinateLineTransformFilter = parallelCoordinateLineTransformFilter;
//    [parallelCoordinateLineTransformFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime){
//        UIImage *intermediateImage = [weakParallelCoordinateLineTransformFilter imageFromCurrentFramebuffer];
//        [weakIntermediateImages addObject:intermediateImage];
//    }];

    __unsafe_unretained GPUImageOutput<GPUImageInput> *weakNonMaximumSuppressionFilter = nonMaximumSuppressionFilter;
    [nonMaximumSuppressionFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime){
        UIImage *intermediateImage = [weakNonMaximumSuppressionFilter imageFromCurrentFramebuffer];
        [weakIntermediateImages addObject:intermediateImage];

        [weakSelf extractLineParametersFromImageAtFrameTime:frameTime];
    }];
#else
    [nonMaximumSuppressionFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime) {
        [weakSelf extractLineParametersFromImageAtFrameTime:frameTime];
    }];
#endif
    
    [thresholdEdgeDetectionFilter addTarget:parallelCoordinateLineTransformFilter];
    [parallelCoordinateLineTransformFilter addTarget:nonMaximumSuppressionFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:thresholdEdgeDetectionFilter, nil];
    //    self.terminalFilter = colorPackingFilter;
    self.terminalFilter = nonMaximumSuppressionFilter;
    
//    self.edgeThreshold = 0.95;
    self.lineDetectionThreshold = 0.12;
    
    return self;
}

- (void)dealloc;
{
    free(rawImagePixels);
    free(linesArray);
}

#pragma mark -
#pragma mark Corner extraction

- (void)extractLineParametersFromImageAtFrameTime:(CMTime)frameTime;
{
    // we need a normal color texture for this filter
    NSAssert(self.outputTextureOptions.internalFormat == GL_RGBA, @"The output texture format for this filter must be GL_RGBA.");
    NSAssert(self.outputTextureOptions.type == GL_UNSIGNED_BYTE, @"The type of the output texture of this filter must be GL_UNSIGNED_BYTE.");
    
    NSUInteger numberOfLines = 0;
    CGSize imageSize = nonMaximumSuppressionFilter.outputFrameSize;
    
    unsigned int imageByteSize = imageSize.width * imageSize.height * 4;
    
    if (rawImagePixels == NULL)
    {
        rawImagePixels = (GLubyte *)malloc(imageByteSize);
        linesArray = calloc(1024 * 2, sizeof(GLfloat));
    }
    
    glReadPixels(0, 0, (int)imageSize.width, (int)imageSize.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);
    
//    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    unsigned int imageWidth = imageSize.width * 4;
    
    unsigned int currentByte = 0;
    unsigned int cornerStorageIndex = 0;
    unsigned long lineStrengthCounter = 0;
    while (currentByte < imageByteSize)
    {
        GLubyte colorByte = rawImagePixels[currentByte];
//        NSLog(@"(%d,%d): [%d,%d,%d,%d]", xCoordinate, yCoordinate, rawImagePixels[currentByte], rawImagePixels[currentByte+1], rawImagePixels[currentByte+2], rawImagePixels[currentByte+3]);
//        NSLog(@"[%d,%d,%d,%d]", rawImagePixels[currentByte], rawImagePixels[currentByte+1], rawImagePixels[currentByte+2], rawImagePixels[currentByte+3]);
        
        if (colorByte > 0)
        {
            unsigned int xCoordinate = currentByte % imageWidth;
            unsigned int yCoordinate = currentByte / imageWidth;
            
            lineStrengthCounter += colorByte;
//            NSLog(@"(%d,%d): [%d,%d,%d,%d]", xCoordinate, yCoordinate, rawImagePixels[currentByte], rawImagePixels[currentByte+1], rawImagePixels[currentByte+2], rawImagePixels[currentByte+3]);
          
            CGFloat normalizedXCoordinate = -1.0 + 2.0 * (CGFloat)(xCoordinate / 4) / imageSize.width;
            CGFloat normalizedYCoordinate = -1.0 + 2.0 * (CGFloat)(yCoordinate) / imageSize.height;
            
            if (normalizedXCoordinate < 0.0)
            {
                // T space
                // m = -1 - d/u
                // b = d * v/u
                if (normalizedXCoordinate > -0.05) // Test for the case right near the X axis, stamp the X intercept instead of the Y
                {
                    linesArray[cornerStorageIndex++] = 100000.0;
                    linesArray[cornerStorageIndex++] = normalizedYCoordinate;
                }
                else
                {
                    linesArray[cornerStorageIndex++] = -1.0 - 1.0 / normalizedXCoordinate;
                    linesArray[cornerStorageIndex++] = 1.0 * normalizedYCoordinate / normalizedXCoordinate;
                }
            }
            else
            {
                // S space
                // m = 1 - d/u
                // b = d * v/u
                if (normalizedXCoordinate < 0.05) // Test for the case right near the X axis, stamp the X intercept instead of the Y
                {
                    linesArray[cornerStorageIndex++] = 100000.0;
                    linesArray[cornerStorageIndex++] = normalizedYCoordinate;
                }
                else
                {
                    linesArray[cornerStorageIndex++] = 1.0 - 1.0 / normalizedXCoordinate;
                    linesArray[cornerStorageIndex++] = 1.0 * normalizedYCoordinate / normalizedXCoordinate;
                }
            }
            
            numberOfLines++;
            
            numberOfLines = MIN(numberOfLines, 1023);
            cornerStorageIndex = MIN(cornerStorageIndex, 2040);
        }
        currentByte +=4;
    }
    
//    CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
//    NSLog(@"Processing time : %f ms", 1000.0 * currentFrameTime);

    if (linesDetectedBlock != NULL)
    {
        linesDetectedBlock(linesArray, numberOfLines, frameTime);
    }
}

- (BOOL)wantsMonochromeInput;
{
//    return YES;
    return NO;
}

#pragma mark -
#pragma mark Accessors

//- (void)setEdgeThreshold:(CGFloat)newValue;
//{
//    [(GPUImageCannyEdgeDetectionFilter *)thresholdEdgeDetectionFilter setThreshold:newValue];
//}
//
//- (CGFloat)edgeThreshold;
//{
//    return [(GPUImageCannyEdgeDetectionFilter *)thresholdEdgeDetectionFilter threshold];
//}

- (void)setLineDetectionThreshold:(CGFloat)newValue;
{
    nonMaximumSuppressionFilter.threshold = newValue;
}

- (CGFloat)lineDetectionThreshold;
{
    return nonMaximumSuppressionFilter.threshold;
}

#ifdef DEBUGLINEDETECTION
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
//    [thresholdEdgeDetectionFilter useNextFrameForImageCapture];
//    [parallelCoordinateLineTransformFilter useNextFrameForImageCapture];
    [nonMaximumSuppressionFilter useNextFrameForImageCapture];
    
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
}
#endif

@end

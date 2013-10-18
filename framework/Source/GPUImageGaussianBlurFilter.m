#import "GPUImageGaussianBlurFilter.h"

@implementation GPUImageGaussianBlurFilter

@synthesize blurSize = _blurSize;
@synthesize blurRadiusInPixels = _blurRadiusInPixels;
@synthesize blurRadiusAsFractionOfImageWidth  = _blurRadiusAsFractionOfImageWidth;
@synthesize blurRadiusAsFractionOfImageHeight = _blurRadiusAsFractionOfImageHeight;
@synthesize blurPasses = _blurPasses;

#pragma mark -
#pragma mark Initialization and teardown

- (id) initWithFirstStageVertexShaderFromString:(NSString *)firstStageVertexShaderString 
             firstStageFragmentShaderFromString:(NSString *)firstStageFragmentShaderString 
              secondStageVertexShaderFromString:(NSString *)secondStageVertexShaderString
            secondStageFragmentShaderFromString:(NSString *)secondStageFragmentShaderString
{
    
//    NSString *currentGaussianBlurVertexShader = [GPUImageGaussianBlurFilter vertexShaderForStandardGaussianOfRadius:4 sigma:2.0];
//    NSString *currentGaussianBlurFragmentShader = [GPUImageGaussianBlurFilter fragmentShaderForStandardGaussianOfRadius:4 sigma:2.0];
    NSString *currentGaussianBlurVertexShader = [GPUImageGaussianBlurFilter vertexShaderForOptimizedGaussianOfRadius:4 sigma:2.0];
    NSString *currentGaussianBlurFragmentShader = [GPUImageGaussianBlurFilter fragmentShaderForOptimizedGaussianOfRadius:4 sigma:2.0];
    
    if (!(self = [super initWithFirstStageVertexShaderFromString:firstStageVertexShaderString ? firstStageVertexShaderString : currentGaussianBlurVertexShader
                              firstStageFragmentShaderFromString:firstStageFragmentShaderString ? firstStageFragmentShaderString : currentGaussianBlurFragmentShader
                               secondStageVertexShaderFromString:secondStageVertexShaderString ? secondStageVertexShaderString : currentGaussianBlurVertexShader
                             secondStageFragmentShaderFromString:secondStageFragmentShaderString ? secondStageFragmentShaderString : currentGaussianBlurFragmentShader])) {
        return nil;
    }
    
    self.blurSize = 1.0;
    _blurRadiusInPixels = 2.0;
    shouldResizeBlurRadiusWithImageSize = NO;
    
//    NSLog(@"Optimized vertex shader: \n%@", [GPUImageGaussianBlurFilter vertexShaderForOptimizedGaussianOfRadius:4 sigma:1.833333]);
//    NSLog(@"Optimized fragment shader: \n%@", [GPUImageGaussianBlurFilter fragmentShaderForOptimizedGaussianOfRadius:4 sigma:1.833333]);
    return self;
}

- (id)init;
{
    return [self initWithFirstStageVertexShaderFromString:nil
                       firstStageFragmentShaderFromString:nil
                        secondStageVertexShaderFromString:nil
                      secondStageFragmentShaderFromString:nil];
}

#pragma mark -
#pragma mark Auto-generation of optimized Gaussian shaders

// "Implementation limit of 32 varying components exceeded" - Max number of varyings for these GPUs

+ (NSString *)vertexShaderForStandardGaussianOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma;
{
//    NSLog(@"Max varyings: %d", [GPUImageContext maximumVaryingVectorsForThisDevice]);
    NSMutableString *shaderString = [[NSMutableString alloc] init];

    // Header
    [shaderString appendFormat:@"\
      attribute vec4 position;\n\
      attribute vec4 inputTextureCoordinate;\n\
      \n\
      uniform float texelWidthOffset;\n\
      uniform float texelHeightOffset;\n\
      \n\
      varying vec2 blurCoordinates[%d];\n\
      \n\
      void main()\n\
      {\n\
          gl_Position = position;\n\
          \n\
          vec2 singleStepOffset = vec2(texelWidthOffset, texelHeightOffset);\n", (blurRadius * 2 + 1) ];

    // Inner offset loop
    for (NSUInteger currentBlurCoordinateIndex = 0; currentBlurCoordinateIndex < (blurRadius * 2 + 1); currentBlurCoordinateIndex++)
    {
        NSInteger offsetFromCenter = currentBlurCoordinateIndex - blurRadius;
        if (offsetFromCenter < 0)
        {
            [shaderString appendFormat:@"blurCoordinates[%d] = inputTextureCoordinate.xy - singleStepOffset * %f;\n", currentBlurCoordinateIndex, (GLfloat)(-offsetFromCenter)];
        }
        else if (offsetFromCenter > 0)
        {
            [shaderString appendFormat:@"blurCoordinates[%d] = inputTextureCoordinate.xy + singleStepOffset * %f;\n", currentBlurCoordinateIndex, (GLfloat)(offsetFromCenter)];
        }
        else
        {
            [shaderString appendFormat:@"blurCoordinates[%d] = inputTextureCoordinate.xy;\n", currentBlurCoordinateIndex];
        }
    }
    
    // Footer
    [shaderString appendString:@"}\n"];
    
    return shaderString;
}

+ (NSString *)fragmentShaderForStandardGaussianOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma;
{
    // First, generate the normal Gaussian weights for a given sigma
    GLfloat *standardGaussianWeights = calloc(blurRadius + 1, sizeof(GLfloat));
    GLfloat sumOfWeights = 0.0;
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++)
    {
        standardGaussianWeights[currentGaussianWeightIndex] = (1.0 / sqrt(2.0 * M_PI * pow(sigma, 2.0))) * exp(-pow(currentGaussianWeightIndex, 2.0) / (2.0 * pow(sigma, 2.0)));

        if (currentGaussianWeightIndex == 0)
        {
            sumOfWeights += standardGaussianWeights[currentGaussianWeightIndex];
        }
        else
        {
            sumOfWeights += 2.0 * standardGaussianWeights[currentGaussianWeightIndex];
        }
    }

    // Next, normalize these weights to prevent the clipping of the Gaussian curve at the end of the discrete samples from reducing luminance
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++)
    {
        standardGaussianWeights[currentGaussianWeightIndex] = standardGaussianWeights[currentGaussianWeightIndex] / sumOfWeights;
    }

    // Finally, generate the shader from these weights
    NSMutableString *shaderString = [[NSMutableString alloc] init];
    
    // Header
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    [shaderString appendFormat:@"\
     uniform sampler2D inputImageTexture;\n\
     \n\
     varying highp vec2 blurCoordinates[%d];\n\
     \n\
     void main()\n\
     {\n\
        lowp vec4 sum = vec4(0.0);\n", (blurRadius * 2 + 1) ];
#else
    [shaderString appendFormat:@"\
     uniform sampler2D inputImageTexture;\n\
     \n\
     varying vec2 blurCoordinates[%d];\n\
     \n\
     void main()\n\
     {\n\
        vec4 sum = vec4(0.0);\n", (blurRadius * 2 + 1) ];
#endif

    // Inner texture loop
    for (NSUInteger currentBlurCoordinateIndex = 0; currentBlurCoordinateIndex < (blurRadius * 2 + 1); currentBlurCoordinateIndex++)
    {
        NSInteger offsetFromCenter = currentBlurCoordinateIndex - blurRadius;
        if (offsetFromCenter < 0)
        {
            [shaderString appendFormat:@"sum += texture2D(inputImageTexture, blurCoordinates[%d]) * %f;\n", currentBlurCoordinateIndex, standardGaussianWeights[-offsetFromCenter]];
        }
        else
        {
            [shaderString appendFormat:@"sum += texture2D(inputImageTexture, blurCoordinates[%d]) * %f;\n", currentBlurCoordinateIndex, standardGaussianWeights[offsetFromCenter]];
        }
    }

    // Footer
    [shaderString appendString:@"\
     gl_FragColor = sum;\n\
     }\n"];
    
    free(standardGaussianWeights);
    return shaderString;
}

+ (NSString *)vertexShaderForOptimizedGaussianOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma;
{
    if (blurRadius == 0)
    {
        return nil;
    }
    // First, generate the normal Gaussian weights for a given sigma
    GLfloat *standardGaussianWeights = calloc(blurRadius + 1, sizeof(GLfloat));
    GLfloat sumOfWeights = 0.0;
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++)
    {
        standardGaussianWeights[currentGaussianWeightIndex] = (1.0 / sqrt(2.0 * M_PI * pow(sigma, 2.0))) * exp(-pow(currentGaussianWeightIndex, 2.0) / (2.0 * pow(sigma, 2.0)));
        
        if (currentGaussianWeightIndex == 0)
        {
            sumOfWeights += standardGaussianWeights[currentGaussianWeightIndex];
        }
        else
        {
            sumOfWeights += 2.0 * standardGaussianWeights[currentGaussianWeightIndex];
        }
    }
    
    // Next, normalize these weights to prevent the clipping of the Gaussian curve at the end of the discrete samples from reducing luminance
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++)
    {
        standardGaussianWeights[currentGaussianWeightIndex] = standardGaussianWeights[currentGaussianWeightIndex] / sumOfWeights;
    }

    // From these weights we calculate the offsets to read interpolated values from
    NSUInteger numberOfOptimizedOffsets = MIN(blurRadius / 2 + (blurRadius % 2), 7);
    GLfloat *optimizedGaussianOffsets = calloc(numberOfOptimizedOffsets, sizeof(GLfloat));
    
    for (NSUInteger currentOptimizedOffset = 0; currentOptimizedOffset < numberOfOptimizedOffsets; currentOptimizedOffset++)
    {
        GLfloat firstWeight = standardGaussianWeights[currentOptimizedOffset*2 + 1];
        GLfloat secondWeight = standardGaussianWeights[currentOptimizedOffset*2 + 2];
        
        GLfloat optimizedWeight = firstWeight + secondWeight;
        
        optimizedGaussianOffsets[currentOptimizedOffset] = (firstWeight * (currentOptimizedOffset*2 + 1) + secondWeight * (currentOptimizedOffset*2 + 2)) / optimizedWeight;
    }
    
    NSMutableString *shaderString = [[NSMutableString alloc] init];
    // Header
    [shaderString appendFormat:@"\
     attribute vec4 position;\n\
     attribute vec4 inputTextureCoordinate;\n\
     \n\
     uniform float texelWidthOffset;\n\
     uniform float texelHeightOffset;\n\
     \n\
     varying vec2 blurCoordinates[%d];\n\
     \n\
     void main()\n\
     {\n\
        gl_Position = position;\n\
        \n\
        vec2 singleStepOffset = vec2(texelWidthOffset, texelHeightOffset);\n", 1 + (numberOfOptimizedOffsets * 2)];

    // Inner offset loop
    [shaderString appendString:@"blurCoordinates[0] = inputTextureCoordinate.xy;\n"];
    for (NSUInteger currentOptimizedOffset = 0; currentOptimizedOffset < numberOfOptimizedOffsets; currentOptimizedOffset++)
    {
        [shaderString appendFormat:@"\
         blurCoordinates[%d] = inputTextureCoordinate.xy + singleStepOffset * %f;\n\
         blurCoordinates[%d] = inputTextureCoordinate.xy - singleStepOffset * %f;\n", (currentOptimizedOffset * 2) + 1, optimizedGaussianOffsets[currentOptimizedOffset], (currentOptimizedOffset * 2) + 2, optimizedGaussianOffsets[currentOptimizedOffset]];
    }
    
    // Footer
    [shaderString appendString:@"}\n"];

    free(optimizedGaussianOffsets);
    free(standardGaussianWeights);
    return shaderString;
}

+ (NSString *)fragmentShaderForOptimizedGaussianOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma;
{
    if (blurRadius == 0)
    {
        return nil;
    }
    // First, generate the normal Gaussian weights for a given sigma
    GLfloat *standardGaussianWeights = calloc(blurRadius + 1, sizeof(GLfloat));
    GLfloat sumOfWeights = 0.0;
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++)
    {
        standardGaussianWeights[currentGaussianWeightIndex] = (1.0 / sqrt(2.0 * M_PI * pow(sigma, 2.0))) * exp(-pow(currentGaussianWeightIndex, 2.0) / (2.0 * pow(sigma, 2.0)));
        
        if (currentGaussianWeightIndex == 0)
        {
            sumOfWeights += standardGaussianWeights[currentGaussianWeightIndex];
        }
        else
        {
            sumOfWeights += 2.0 * standardGaussianWeights[currentGaussianWeightIndex];
        }
    }
    
    // Next, normalize these weights to prevent the clipping of the Gaussian curve at the end of the discrete samples from reducing luminance
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++)
    {
        standardGaussianWeights[currentGaussianWeightIndex] = standardGaussianWeights[currentGaussianWeightIndex] / sumOfWeights;
    }
    
    // From these weights we calculate the offsets to read interpolated values from
    NSUInteger numberOfOptimizedOffsets = MIN(blurRadius / 2 + (blurRadius % 2), 7);
    NSUInteger trueNumberOfOptimizedOffsets = blurRadius / 2 + (blurRadius % 2);

    NSMutableString *shaderString = [[NSMutableString alloc] init];
    
    // Header
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    [shaderString appendFormat:@"\
     uniform sampler2D inputImageTexture;\n\
     uniform highp float texelWidthOffset;\n\
     uniform highp float texelHeightOffset;\n\
     \n\
     varying highp vec2 blurCoordinates[%d];\n\
     \n\
     void main()\n\
     {\n\
        lowp vec4 sum = vec4(0.0);\n", 1 + (numberOfOptimizedOffsets * 2) ];
#else
    [shaderString appendFormat:@"\
     uniform sampler2D inputImageTexture;\n\
     uniform float texelWidthOffset;\n\
     uniform float texelHeightOffset;\n\
     \n\
     varying vec2 blurCoordinates[%d];\n\
     \n\
     void main()\n\
     {\n\
        vec4 sum = vec4(0.0);\n", 1 + (numberOfOptimizedOffsets * 2) ];
#endif

    // Inner texture loop
    [shaderString appendFormat:@"sum += texture2D(inputImageTexture, blurCoordinates[0]) * %f;\n", standardGaussianWeights[0]];
    
    for (NSUInteger currentBlurCoordinateIndex = 0; currentBlurCoordinateIndex < numberOfOptimizedOffsets; currentBlurCoordinateIndex++)
    {
        GLfloat firstWeight = standardGaussianWeights[currentBlurCoordinateIndex * 2 + 1];
        GLfloat secondWeight = standardGaussianWeights[currentBlurCoordinateIndex * 2 + 2];
        GLfloat optimizedWeight = firstWeight + secondWeight;

        [shaderString appendFormat:@"sum += texture2D(inputImageTexture, blurCoordinates[%d]) * %f;\n", (currentBlurCoordinateIndex * 2) + 1, optimizedWeight];
        [shaderString appendFormat:@"sum += texture2D(inputImageTexture, blurCoordinates[%d]) * %f;\n", (currentBlurCoordinateIndex * 2) + 2, optimizedWeight];
    }
    
    // If the number of required samples exceeds the amount we can pass in via varyings, we have to do dependent texture reads in the fragment shader
    if (trueNumberOfOptimizedOffsets > numberOfOptimizedOffsets)
    {
        [shaderString appendString:@"highp vec2 singleStepOffset = vec2(texelWidthOffset, texelHeightOffset);\n"];

        for (NSUInteger currentOverlowTextureRead = numberOfOptimizedOffsets; currentOverlowTextureRead < trueNumberOfOptimizedOffsets; currentOverlowTextureRead++)
        {
            GLfloat firstWeight = standardGaussianWeights[currentOverlowTextureRead * 2 + 1];
            GLfloat secondWeight = standardGaussianWeights[currentOverlowTextureRead * 2 + 2];
            
            GLfloat optimizedWeight = firstWeight + secondWeight;
            GLfloat optimizedOffset = (firstWeight * (currentOverlowTextureRead * 2 + 1) + secondWeight * (currentOverlowTextureRead * 2 + 2)) / optimizedWeight;
            
            [shaderString appendFormat:@"sum += texture2D(inputImageTexture, blurCoordinates[0] + singleStepOffset * %f) * %f;\n", optimizedOffset, optimizedWeight];
            [shaderString appendFormat:@"sum += texture2D(inputImageTexture, blurCoordinates[0] - singleStepOffset * %f) * %f;\n", optimizedOffset, optimizedWeight];
        }
    }
    
    // Footer
    [shaderString appendString:@"\
        gl_FragColor = sum;\n\
     }\n"];

    free(standardGaussianWeights);
    return shaderString;
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    [super setupFilterForSize:filterFrameSize];
    
    if (shouldResizeBlurRadiusWithImageSize == YES)
    {
        
    }
}

#pragma mark -
#pragma mark Rendering

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates sourceTexture:sourceTexture];
    
    for (NSUInteger currentAdditionalBlurPass = 1; currentAdditionalBlurPass < _blurPasses; currentAdditionalBlurPass++)
    {
        [super renderToTextureWithVertices:vertices textureCoordinates:[[self class] textureCoordinatesForRotation:kGPUImageNoRotation] sourceTexture:secondFilterOutputTexture];
    }
}

- (void)switchToVertexShader:(NSString *)newVertexShader fragmentShader:(NSString *)newFragmentShader;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];

        filterProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:newVertexShader fragmentShaderString:newFragmentShader];
        
        if (!filterProgram.initialized)
        {
            [self initializeAttributes];
            
            if (![filterProgram link])
            {
                NSString *progLog = [filterProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [filterProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [filterProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                filterProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        
        filterPositionAttribute = [filterProgram attributeIndex:@"position"];
        filterTextureCoordinateAttribute = [filterProgram attributeIndex:@"inputTextureCoordinate"];
        filterInputTextureUniform = [filterProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
        verticalPassTexelWidthOffsetUniform = [filterProgram uniformIndex:@"texelWidthOffset"];
        verticalPassTexelHeightOffsetUniform = [filterProgram uniformIndex:@"texelHeightOffset"];
        [GPUImageContext setActiveShaderProgram:filterProgram];

        glEnableVertexAttribArray(filterPositionAttribute);
        glEnableVertexAttribArray(filterTextureCoordinateAttribute);

        secondFilterProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:newVertexShader fragmentShaderString:newFragmentShader];
        
        if (!secondFilterProgram.initialized)
        {
            [self initializeSecondaryAttributes];
            
            if (![secondFilterProgram link])
            {
                NSString *progLog = [secondFilterProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [secondFilterProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [secondFilterProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                secondFilterProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        
        secondFilterPositionAttribute = [secondFilterProgram attributeIndex:@"position"];
        secondFilterTextureCoordinateAttribute = [secondFilterProgram attributeIndex:@"inputTextureCoordinate"];
        secondFilterInputTextureUniform = [secondFilterProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
        secondFilterInputTextureUniform2 = [secondFilterProgram uniformIndex:@"inputImageTexture2"]; // This does assume a name of "inputImageTexture2" for second input texture in the fragment shader
        horizontalPassTexelWidthOffsetUniform = [secondFilterProgram uniformIndex:@"texelWidthOffset"];
        horizontalPassTexelHeightOffsetUniform = [secondFilterProgram uniformIndex:@"texelHeightOffset"];
        [GPUImageContext setActiveShaderProgram:secondFilterProgram];

        glEnableVertexAttribArray(secondFilterPositionAttribute);
        glEnableVertexAttribArray(secondFilterTextureCoordinateAttribute);
        
        [self setupFilterForSize:[self sizeOfFBO]];
    });

}

#pragma mark -
#pragma mark Accessors

- (void)setBlurSize:(CGFloat)newValue;
{
    _blurSize = newValue;
    
    _verticalTexelSpacing = _blurSize;
    _horizontalTexelSpacing = _blurSize;
    
    [self setupFilterForSize:[self sizeOfFBO]];
}

// inputRadius for Core Image's CIGaussianBlur is really sigma in the Gaussian equation, so I'm using that for my blur radius, to be consistent
- (void)setBlurRadiusInPixels:(CGFloat)newValue;
{
    // 7.0 is the limit for blur size for hardcoded varying offsets

    if (newValue != _blurRadiusInPixels)
    {
        _blurRadiusInPixels = round(newValue); // For now, only do even blur sizes (based on a multiple of two of the sigma)
//        _blurRadiusInPixels = (round(newValue * 2.0)) / 2.0; // Only take this in half-pixel steps to minimize shader creation, yet provide single pixel blur resolution
        
        NSString *newGaussianBlurVertexShader = [GPUImageGaussianBlurFilter vertexShaderForOptimizedGaussianOfRadius:(_blurRadiusInPixels * 2) sigma:_blurRadiusInPixels];
        NSString *newGaussianBlurFragmentShader = [GPUImageGaussianBlurFilter fragmentShaderForOptimizedGaussianOfRadius:(_blurRadiusInPixels * 2) sigma:_blurRadiusInPixels];
//        NSString *newGaussianBlurVertexShader = [GPUImageGaussianBlurFilter vertexShaderForOptimizedGaussianOfRadius:round(_blurRadiusInPixels * 2)/2 sigma:_blurRadiusInPixels];
//        NSString *newGaussianBlurFragmentShader = [GPUImageGaussianBlurFilter fragmentShaderForOptimizedGaussianOfRadius:round(_blurRadiusInPixels * 2)/2 sigma:_blurRadiusInPixels];

        [self switchToVertexShader:newGaussianBlurVertexShader fragmentShader:newGaussianBlurFragmentShader];
    }
    shouldResizeBlurRadiusWithImageSize = NO;
}

@end

#import "GPUImageAverageColor.h"

NSString *const kGPUImageColorAveragingVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform float texelWidth;
 uniform float texelHeight;
 
 varying vec2 upperLeftInputTextureCoordinate;
 varying vec2 upperRightInputTextureCoordinate;
 varying vec2 lowerLeftInputTextureCoordinate;
 varying vec2 lowerRightInputTextureCoordinate;
 
 void main()
 {
     gl_Position = position;
     
     upperLeftInputTextureCoordinate = inputTextureCoordinate.xy + vec2(-texelWidth, -texelHeight);
     upperRightInputTextureCoordinate = inputTextureCoordinate.xy + vec2(texelWidth, -texelHeight);
     lowerLeftInputTextureCoordinate = inputTextureCoordinate.xy + vec2(-texelWidth, texelHeight);
     lowerRightInputTextureCoordinate = inputTextureCoordinate.xy + vec2(texelWidth, texelHeight);
 }
 );

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageColorAveragingFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 uniform sampler2D inputImageTexture;
 
 varying highp vec2 outputTextureCoordinate;
 
 varying highp vec2 upperLeftInputTextureCoordinate;
 varying highp vec2 upperRightInputTextureCoordinate;
 varying highp vec2 lowerLeftInputTextureCoordinate;
 varying highp vec2 lowerRightInputTextureCoordinate;
 
 void main()
 {
     highp vec4 upperLeftColor = texture2D(inputImageTexture, upperLeftInputTextureCoordinate);
     highp vec4 upperRightColor = texture2D(inputImageTexture, upperRightInputTextureCoordinate);
     highp vec4 lowerLeftColor = texture2D(inputImageTexture, lowerLeftInputTextureCoordinate);
     highp vec4 lowerRightColor = texture2D(inputImageTexture, lowerRightInputTextureCoordinate);
     
     gl_FragColor = 0.25 * (upperLeftColor + upperRightColor + lowerLeftColor + lowerRightColor);
 }
);
#else
NSString *const kGPUImageColorAveragingFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 varying vec2 outputTextureCoordinate;
 
 varying vec2 upperLeftInputTextureCoordinate;
 varying vec2 upperRightInputTextureCoordinate;
 varying vec2 lowerLeftInputTextureCoordinate;
 varying vec2 lowerRightInputTextureCoordinate;
 
 void main()
 {
     vec4 upperLeftColor = texture2D(inputImageTexture, upperLeftInputTextureCoordinate);
     vec4 upperRightColor = texture2D(inputImageTexture, upperRightInputTextureCoordinate);
     vec4 lowerLeftColor = texture2D(inputImageTexture, lowerLeftInputTextureCoordinate);
     vec4 lowerRightColor = texture2D(inputImageTexture, lowerRightInputTextureCoordinate);
     
     gl_FragColor = 0.25 * (upperLeftColor + upperRightColor + lowerLeftColor + lowerRightColor);
 }
);
#endif

@implementation GPUImageAverageColor

@synthesize colorAverageProcessingFinishedBlock = _colorAverageProcessingFinishedBlock;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageColorAveragingVertexShaderString fragmentShaderFromString:kGPUImageColorAveragingFragmentShaderString]))
    {
        return nil;
    }
    
    texelWidthUniform = [filterProgram uniformIndex:@"texelWidth"];
    texelHeightUniform = [filterProgram uniformIndex:@"texelHeight"];
    finalStageSize = CGSizeMake(1.0, 1.0);
    
    __unsafe_unretained GPUImageAverageColor *weakSelf = self;
    [self setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime) {
        [weakSelf extractAverageColorAtFrameTime:frameTime];
    }];

    return self;
}

- (void)dealloc;
{
    if (rawImagePixels != NULL)
    {
        free(rawImagePixels);
    }
}

#pragma mark -
#pragma mark Managing the display FBOs

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    outputFramebuffer = nil;
    [GPUImageContext setActiveShaderProgram:filterProgram];

    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);

    GLuint currentTexture = [firstInputFramebuffer texture];
    
    NSUInteger numberOfReductionsInX = floor(log(inputTextureSize.width) / log(4.0));
    NSUInteger numberOfReductionsInY = floor(log(inputTextureSize.height) / log(4.0));
    NSUInteger reductionsToHitSideLimit = MIN(numberOfReductionsInX, numberOfReductionsInY);
    for (NSUInteger currentReduction = 0; currentReduction < reductionsToHitSideLimit; currentReduction++)
    {
        CGSize currentStageSize = CGSizeMake(floor(inputTextureSize.width / pow(4.0, currentReduction + 1.0)), floor(inputTextureSize.height / pow(4.0, currentReduction + 1.0)));

        [outputFramebuffer unlock];
        outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:currentStageSize textureOptions:self.outputTextureOptions onlyTexture:NO];
        [outputFramebuffer activateFramebuffer];

        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, currentTexture);
        
        glUniform1i(filterInputTextureUniform, 2);
        
        glUniform1f(texelWidthUniform, 0.25 / currentStageSize.width);
        glUniform1f(texelHeightUniform, 0.25 / currentStageSize.height);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        currentTexture = [outputFramebuffer texture];
        finalStageSize = currentStageSize;
    }

    [firstInputFramebuffer unlock];
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    inputRotation = kGPUImageNoRotation;
}

- (void)extractAverageColorAtFrameTime:(CMTime)frameTime;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        // we need a normal color texture for averaging the color values
        NSAssert(self.outputTextureOptions.internalFormat == GL_RGBA, @"The output texture internal format for this filter must be GL_RGBA.");
        NSAssert(self.outputTextureOptions.type == GL_UNSIGNED_BYTE, @"The type of the output texture of this filter must be GL_UNSIGNED_BYTE.");
        
        NSUInteger totalNumberOfPixels = round(finalStageSize.width * finalStageSize.height);
        
        if (rawImagePixels == NULL)
        {
            rawImagePixels = (GLubyte *)malloc(totalNumberOfPixels * 4);
        }
        
        [GPUImageContext useImageProcessingContext];
        [outputFramebuffer activateFramebuffer];
        glReadPixels(0, 0, (int)finalStageSize.width, (int)finalStageSize.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);
        
        NSUInteger redTotal = 0, greenTotal = 0, blueTotal = 0, alphaTotal = 0;
        NSUInteger byteIndex = 0;
        for (NSUInteger currentPixel = 0; currentPixel < totalNumberOfPixels; currentPixel++)
        {
            redTotal += rawImagePixels[byteIndex++];
            greenTotal += rawImagePixels[byteIndex++];
            blueTotal += rawImagePixels[byteIndex++];
            alphaTotal += rawImagePixels[byteIndex++];
        }
        
        CGFloat normalizedRedTotal = (CGFloat)redTotal / (CGFloat)totalNumberOfPixels / 255.0;
        CGFloat normalizedGreenTotal = (CGFloat)greenTotal / (CGFloat)totalNumberOfPixels / 255.0;
        CGFloat normalizedBlueTotal = (CGFloat)blueTotal / (CGFloat)totalNumberOfPixels / 255.0;
        CGFloat normalizedAlphaTotal = (CGFloat)alphaTotal / (CGFloat)totalNumberOfPixels / 255.0;
        
        if (_colorAverageProcessingFinishedBlock != NULL)
        {
            _colorAverageProcessingFinishedBlock(normalizedRedTotal, normalizedGreenTotal, normalizedBlueTotal, normalizedAlphaTotal, frameTime);
        }
    });
}

@end

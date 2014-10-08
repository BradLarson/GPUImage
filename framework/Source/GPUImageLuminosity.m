#import "GPUImageLuminosity.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageInitialLuminosityFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 uniform sampler2D inputImageTexture;
 
 varying highp vec2 outputTextureCoordinate;
 
 varying highp vec2 upperLeftInputTextureCoordinate;
 varying highp vec2 upperRightInputTextureCoordinate;
 varying highp vec2 lowerLeftInputTextureCoordinate;
 varying highp vec2 lowerRightInputTextureCoordinate;
 
 const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

 void main()
 {
     highp float upperLeftLuminance = dot(texture2D(inputImageTexture, upperLeftInputTextureCoordinate).rgb, W);
     highp float upperRightLuminance = dot(texture2D(inputImageTexture, upperRightInputTextureCoordinate).rgb, W);
     highp float lowerLeftLuminance = dot(texture2D(inputImageTexture, lowerLeftInputTextureCoordinate).rgb, W);
     highp float lowerRightLuminance = dot(texture2D(inputImageTexture, lowerRightInputTextureCoordinate).rgb, W);

     highp float luminosity = 0.25 * (upperLeftLuminance + upperRightLuminance + lowerLeftLuminance + lowerRightLuminance);
     gl_FragColor = vec4(luminosity, luminosity, luminosity, 1.0);
 }
);

NSString *const kGPUImageLuminosityFragmentShaderString = SHADER_STRING
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
     highp float upperLeftLuminance = texture2D(inputImageTexture, upperLeftInputTextureCoordinate).r;
     highp float upperRightLuminance = texture2D(inputImageTexture, upperRightInputTextureCoordinate).r;
     highp float lowerLeftLuminance = texture2D(inputImageTexture, lowerLeftInputTextureCoordinate).r;
     highp float lowerRightLuminance = texture2D(inputImageTexture, lowerRightInputTextureCoordinate).r;
     
     highp float luminosity = 0.25 * (upperLeftLuminance + upperRightLuminance + lowerLeftLuminance + lowerRightLuminance);
     gl_FragColor = vec4(luminosity, luminosity, luminosity, 1.0);
 }
);
#else
NSString *const kGPUImageInitialLuminosityFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 varying vec2 outputTextureCoordinate;
 
 varying vec2 upperLeftInputTextureCoordinate;
 varying vec2 upperRightInputTextureCoordinate;
 varying vec2 lowerLeftInputTextureCoordinate;
 varying vec2 lowerRightInputTextureCoordinate;
 
 const vec3 W = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     float upperLeftLuminance = dot(texture2D(inputImageTexture, upperLeftInputTextureCoordinate).rgb, W);
     float upperRightLuminance = dot(texture2D(inputImageTexture, upperRightInputTextureCoordinate).rgb, W);
     float lowerLeftLuminance = dot(texture2D(inputImageTexture, lowerLeftInputTextureCoordinate).rgb, W);
     float lowerRightLuminance = dot(texture2D(inputImageTexture, lowerRightInputTextureCoordinate).rgb, W);
     
     float luminosity = 0.25 * (upperLeftLuminance + upperRightLuminance + lowerLeftLuminance + lowerRightLuminance);
     gl_FragColor = vec4(luminosity, luminosity, luminosity, 1.0);
 }
);

NSString *const kGPUImageLuminosityFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 varying vec2 outputTextureCoordinate;
 
 varying vec2 upperLeftInputTextureCoordinate;
 varying vec2 upperRightInputTextureCoordinate;
 varying vec2 lowerLeftInputTextureCoordinate;
 varying vec2 lowerRightInputTextureCoordinate;
 
 void main()
 {
     float upperLeftLuminance = texture2D(inputImageTexture, upperLeftInputTextureCoordinate).r;
     float upperRightLuminance = texture2D(inputImageTexture, upperRightInputTextureCoordinate).r;
     float lowerLeftLuminance = texture2D(inputImageTexture, lowerLeftInputTextureCoordinate).r;
     float lowerRightLuminance = texture2D(inputImageTexture, lowerRightInputTextureCoordinate).r;
     
     float luminosity = 0.25 * (upperLeftLuminance + upperRightLuminance + lowerLeftLuminance + lowerRightLuminance);
     gl_FragColor = vec4(luminosity, luminosity, luminosity, 1.0);
 }
);
#endif

@implementation GPUImageLuminosity

@synthesize luminosityProcessingFinishedBlock = _luminosityProcessingFinishedBlock;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageColorAveragingVertexShaderString fragmentShaderFromString:kGPUImageInitialLuminosityFragmentShaderString]))
    {
        return nil;
    }
    
    texelWidthUniform = [filterProgram uniformIndex:@"texelWidth"];
    texelHeightUniform = [filterProgram uniformIndex:@"texelHeight"];
        
    __unsafe_unretained GPUImageLuminosity *weakSelf = self;
    [self setFrameProcessingCompletionBlock:^(GPUImageOutput *filter, CMTime frameTime) {
        [weakSelf extractLuminosityAtFrameTime:frameTime];
    }];

    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        secondFilterProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageColorAveragingVertexShaderString fragmentShaderString:kGPUImageLuminosityFragmentShaderString];
        
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
                filterProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        
        secondFilterPositionAttribute = [secondFilterProgram attributeIndex:@"position"];
        secondFilterTextureCoordinateAttribute = [secondFilterProgram attributeIndex:@"inputTextureCoordinate"];
        secondFilterInputTextureUniform = [secondFilterProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
        secondFilterInputTextureUniform2 = [secondFilterProgram uniformIndex:@"inputImageTexture2"]; // This does assume a name of "inputImageTexture2" for second input texture in the fragment shader
        
        secondFilterTexelWidthUniform = [secondFilterProgram uniformIndex:@"texelWidth"];
        secondFilterTexelHeightUniform = [secondFilterProgram uniformIndex:@"texelHeight"];

        [GPUImageContext setActiveShaderProgram:secondFilterProgram];
        
        glEnableVertexAttribArray(secondFilterPositionAttribute);
        glEnableVertexAttribArray(secondFilterTextureCoordinateAttribute);
    });

    return self;
}

- (void)initializeSecondaryAttributes;
{
    [secondFilterProgram addAttribute:@"position"];
	[secondFilterProgram addAttribute:@"inputTextureCoordinate"];
}

/*
- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    // Do an initial render pass that both convert to luminance and reduces
    [GPUImageContext setActiveShaderProgram:filterProgram];
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);

    GLuint currentFramebuffer = [[stageFramebuffers objectAtIndex:0] intValue];
    glBindFramebuffer(GL_FRAMEBUFFER, currentFramebuffer);
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    CGSize currentStageSize = [[stageSizes objectAtIndex:0] CGSizeValue];
#else
    NSSize currentStageSize = [[stageSizes objectAtIndex:0] sizeValue];
#endif
    glViewport(0, 0, (int)currentStageSize.width, (int)currentStageSize.height);

    GLuint currentTexture = [firstInputFramebuffer texture];

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, currentTexture);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    glUniform1f(texelWidthUniform, 0.5 / currentStageSize.width);
    glUniform1f(texelHeightUniform, 0.5 / currentStageSize.height);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    currentTexture = [[stageTextures objectAtIndex:0] intValue];

    // Just perform reductions from this point on
    [GPUImageContext setActiveShaderProgram:secondFilterProgram];
    glVertexAttribPointer(secondFilterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(secondFilterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);

    NSUInteger numberOfStageFramebuffers = [stageFramebuffers count];
    for (NSUInteger currentStage = 1; currentStage < numberOfStageFramebuffers; currentStage++)
    {
        currentFramebuffer = [[stageFramebuffers objectAtIndex:currentStage] intValue];
        glBindFramebuffer(GL_FRAMEBUFFER, currentFramebuffer);
        
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        currentStageSize = [[stageSizes objectAtIndex:currentStage] CGSizeValue];
#else
        currentStageSize = [[stageSizes objectAtIndex:currentStage] sizeValue];
#endif
        glViewport(0, 0, (int)currentStageSize.width, (int)currentStageSize.height);
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, currentTexture);
        
        glUniform1i(secondFilterInputTextureUniform, 2);
        
        glUniform1f(secondFilterTexelWidthUniform, 0.5 / currentStageSize.width);
        glUniform1f(secondFilterTexelHeightUniform, 0.5 / currentStageSize.height);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        currentTexture = [[stageTextures objectAtIndex:currentStage] intValue];
        
//        NSUInteger totalBytesForImage = (int)currentStageSize.width * (int)currentStageSize.height * 4;
//        GLubyte *rawImagePixels2 = (GLubyte *)malloc(totalBytesForImage);
//        glReadPixels(0, 0, (int)currentStageSize.width, (int)currentStageSize.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels2);
//        CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rawImagePixels2, totalBytesForImage, NULL);
//        CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
//
//        CGFloat currentRedTotal = 0.0f, currentGreenTotal = 0.0f, currentBlueTotal = 0.0f, currentAlphaTotal = 0.0f;
//        NSUInteger totalNumberOfPixels = totalBytesForImage / 4;
//
//        for (NSUInteger currentPixel = 0; currentPixel < totalNumberOfPixels; currentPixel++)
//        {
//            currentRedTotal += (CGFloat)rawImagePixels2[(currentPixel * 4)] / 255.0f;
//            currentGreenTotal += (CGFloat)rawImagePixels2[(currentPixel * 4) + 1] / 255.0f;
//            currentBlueTotal += (CGFloat)rawImagePixels2[(currentPixel * 4 + 2)] / 255.0f;
//            currentAlphaTotal += (CGFloat)rawImagePixels2[(currentPixel * 4) + 3] / 255.0f;
//        }
//
//        NSLog(@"Stage %d average image red: %f, green: %f, blue: %f, alpha: %f", currentStage, currentRedTotal / (CGFloat)totalNumberOfPixels, currentGreenTotal / (CGFloat)totalNumberOfPixels, currentBlueTotal / (CGFloat)totalNumberOfPixels, currentAlphaTotal / (CGFloat)totalNumberOfPixels);
//
//
//        CGImageRef cgImageFromBytes = CGImageCreate((int)currentStageSize.width, (int)currentStageSize.height, 8, 32, 4 * (int)currentStageSize.width, defaultRGBColorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaLast, dataProvider, NULL, NO, kCGRenderingIntentDefault);
//
//        UIImage *imageToSave = [UIImage imageWithCGImage:cgImageFromBytes];
//
//        NSData *dataForPNGFile = UIImagePNGRepresentation(imageToSave);
//
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *documentsDirectory = [paths objectAtIndex:0];
//
//        NSString *imageName = [NSString stringWithFormat:@"AverageLevel%d.png", currentStage];
//        NSError *error = nil;
//        if (![dataForPNGFile writeToFile:[documentsDirectory stringByAppendingPathComponent:imageName] options:NSAtomicWrite error:&error])
//        {
//            return;
//        }
    }
    
    [firstInputFramebuffer unlock];
}
 */

#pragma mark -
#pragma mark Callbacks

- (void)extractLuminosityAtFrameTime:(CMTime)frameTime;
{
    runSynchronouslyOnVideoProcessingQueue(^{

        // we need a normal color texture for this filter
        NSAssert(self.outputTextureOptions.internalFormat == GL_RGBA, @"The output texture format for this filter must be GL_RGBA.");
        NSAssert(self.outputTextureOptions.type == GL_UNSIGNED_BYTE, @"The type of the output texture of this filter must be GL_UNSIGNED_BYTE.");
        
        NSUInteger totalNumberOfPixels = round(finalStageSize.width * finalStageSize.height);
        
        if (rawImagePixels == NULL)
        {
            rawImagePixels = (GLubyte *)malloc(totalNumberOfPixels * 4);
        }
        
        [GPUImageContext useImageProcessingContext];
        [outputFramebuffer activateFramebuffer];

        glReadPixels(0, 0, (int)finalStageSize.width, (int)finalStageSize.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);
        
        NSUInteger luminanceTotal = 0;
        NSUInteger byteIndex = 0;
        for (NSUInteger currentPixel = 0; currentPixel < totalNumberOfPixels; currentPixel++)
        {
            luminanceTotal += rawImagePixels[byteIndex];
            byteIndex += 4;
        }
        
        CGFloat normalizedLuminosityTotal = (CGFloat)luminanceTotal / (CGFloat)totalNumberOfPixels / 255.0;
        
        if (_luminosityProcessingFinishedBlock != NULL)
        {
            _luminosityProcessingFinishedBlock(normalizedLuminosityTotal, frameTime);
        }
    });
}


@end

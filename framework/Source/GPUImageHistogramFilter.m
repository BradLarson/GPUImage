#import "GPUImageHistogramFilter.h"

// Unlike other filters, this one uses a grid of GL_POINTs to sample the incoming image in a grid. A custom vertex shader reads the color in the texture at its position 
// and outputs a bin position in the final histogram as the vertex position. That point is then written into the image of the histogram using translucent pixels.
// The degree of translucency is controlled by the scalingFactor, which lets you adjust the dynamic range of the histogram. The histogram can only be generated for one
// color channel or luminance value at a time.
//
// This is based on this implementation: http://www.shaderwrangler.com/publications/histogram/histogram_cameraready.pdf
//
// Or at least that's how it would work if iOS could read from textures in a vertex shader, which it can't. Therefore, I read the texture data down from the
// incoming frame and process the texture colors as vertices.

NSString *const kGPUImageRedHistogramSamplingVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 
 varying vec3 colorFactor;

 void main()
 {
     colorFactor = vec3(1.0, 0.0, 0.0);
     gl_Position = vec4(-1.0 + (position.x * 0.0078125), 0.0, 0.0, 1.0);
     gl_PointSize = 1.0;
 }
);

NSString *const kGPUImageGreenHistogramSamplingVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 
 varying vec3 colorFactor;
 
 void main()
 {
     colorFactor = vec3(0.0, 1.0, 0.0);
     gl_Position = vec4(-1.0 + (position.y * 0.0078125), 0.0, 0.0, 1.0);
     gl_PointSize = 1.0;
 }
);

NSString *const kGPUImageBlueHistogramSamplingVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 
 varying vec3 colorFactor;
 
 void main()
 {
     colorFactor = vec3(0.0, 0.0, 1.0);
     gl_Position = vec4(-1.0 + (position.z * 0.0078125), 0.0, 0.0, 1.0);
     gl_PointSize = 1.0;
 }
);

NSString *const kGPUImageLuminanceHistogramSamplingVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 
 varying vec3 colorFactor;
 
 const vec3 W = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     float luminance = dot(position.xyz, W);

     colorFactor = vec3(1.0, 1.0, 1.0);
     gl_Position = vec4(-1.0 + (luminance * 0.0078125), 0.0, 0.0, 1.0);
     gl_PointSize = 1.0;
 }
);

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageHistogramAccumulationFragmentShaderString = SHADER_STRING
(
 const lowp float scalingFactor = 1.0 / 256.0;

 varying lowp vec3 colorFactor;

 void main()
 {
     gl_FragColor = vec4(colorFactor * scalingFactor , 1.0);
 }
);
#else
NSString *const kGPUImageHistogramAccumulationFragmentShaderString = SHADER_STRING
(
 const float scalingFactor = 1.0 / 256.0;
 
 varying vec3 colorFactor;
 
 void main()
 {
     gl_FragColor = vec4(colorFactor * scalingFactor , 1.0);
 }
);
#endif

@implementation GPUImageHistogramFilter

@synthesize downsamplingFactor = _downsamplingFactor;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithHistogramType:(GPUImageHistogramType)newHistogramType;
{
    switch (newHistogramType)
    {
        case kGPUImageHistogramRed:
        {
            if (!(self = [super initWithVertexShaderFromString:kGPUImageRedHistogramSamplingVertexShaderString fragmentShaderFromString:kGPUImageHistogramAccumulationFragmentShaderString]))
            {
                return nil;
            }
        }; break;
        case kGPUImageHistogramGreen:
        {
            if (!(self = [super initWithVertexShaderFromString:kGPUImageGreenHistogramSamplingVertexShaderString fragmentShaderFromString:kGPUImageHistogramAccumulationFragmentShaderString]))
            {
                return nil;
            }
        }; break;
        case kGPUImageHistogramBlue:
        {
            if (!(self = [super initWithVertexShaderFromString:kGPUImageBlueHistogramSamplingVertexShaderString fragmentShaderFromString:kGPUImageHistogramAccumulationFragmentShaderString]))
            {
                return nil;
            }
        }; break;
        case kGPUImageHistogramLuminance:
        {
            if (!(self = [super initWithVertexShaderFromString:kGPUImageLuminanceHistogramSamplingVertexShaderString fragmentShaderFromString:kGPUImageHistogramAccumulationFragmentShaderString]))
            {
                return nil;
            }
        }; break;
        case kGPUImageHistogramRGB:
        {
            if (!(self = [super initWithVertexShaderFromString:kGPUImageRedHistogramSamplingVertexShaderString fragmentShaderFromString:kGPUImageHistogramAccumulationFragmentShaderString]))
            {
                return nil;
            }
            
            runSynchronouslyOnVideoProcessingQueue(^{
                [GPUImageContext useImageProcessingContext];
                
                secondFilterProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageGreenHistogramSamplingVertexShaderString fragmentShaderString:kGPUImageHistogramAccumulationFragmentShaderString];
                thirdFilterProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageBlueHistogramSamplingVertexShaderString fragmentShaderString:kGPUImageHistogramAccumulationFragmentShaderString];
                
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

                    [GPUImageContext setActiveShaderProgram:secondFilterProgram];
                    
                    glEnableVertexAttribArray(secondFilterPositionAttribute);
                    
                    if (![thirdFilterProgram link])
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
                
                
                thirdFilterPositionAttribute = [thirdFilterProgram attributeIndex:@"position"];
                [GPUImageContext setActiveShaderProgram:thirdFilterProgram];
                
                glEnableVertexAttribArray(thirdFilterPositionAttribute);
            });
        }; break;
    }

    histogramType = newHistogramType;
    
    self.downsamplingFactor = 16;

    return self;
}

- (id)init;
{
    if (!(self = [self initWithHistogramType:kGPUImageHistogramRGB]))
    {
        return nil;
    }

    return self;
}

- (void)initializeSecondaryAttributes;
{
    [secondFilterProgram addAttribute:@"position"];
	[thirdFilterProgram addAttribute:@"position"];
}

- (void)dealloc;
{
    if (vertexSamplingCoordinates != NULL && ![GPUImageContext supportsFastTextureUpload])
    {
        free(vertexSamplingCoordinates);
    }
}

#pragma mark -
#pragma mark Rendering

- (CGSize)sizeOfFBO;
{
    return CGSizeMake(256.0, 3.0);
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    [self renderToTextureWithVertices:NULL textureCoordinates:NULL];
    
    [self informTargetsAboutNewFrameAtTime:frameTime];
}

- (CGSize)outputFrameSize;
{
    return [self sizeOfFBO];
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    if (self.preventRendering)
    {
        return;
    }
    
    inputTextureSize = newSize;
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    inputRotation = kGPUImageNoRotation;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    // we need a normal color texture for this filter
    NSAssert(self.outputTextureOptions.internalFormat == GL_RGBA, @"The output texture format for this filter must be GL_RGBA.");
    NSAssert(self.outputTextureOptions.type == GL_UNSIGNED_BYTE, @"The type of the output texture of this filter must be GL_UNSIGNED_BYTE.");
    
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    [GPUImageContext useImageProcessingContext];

    if ([GPUImageContext supportsFastTextureUpload])
    {
        glFinish();
        vertexSamplingCoordinates = [firstInputFramebuffer byteBuffer];
    } else {
        if (vertexSamplingCoordinates == NULL)
        {
            vertexSamplingCoordinates = calloc(inputTextureSize.width * inputTextureSize.height * 4, sizeof(GLubyte));
        }
        glReadPixels(0, 0, inputTextureSize.width, inputTextureSize.height, GL_RGBA, GL_UNSIGNED_BYTE, vertexSamplingCoordinates);
    }
    
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    [GPUImageContext setActiveShaderProgram:filterProgram];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_ONE, GL_ONE);
    glEnable(GL_BLEND);
    
	glVertexAttribPointer(filterPositionAttribute, 4, GL_UNSIGNED_BYTE, 0, ((unsigned int)_downsamplingFactor - 1) * 4, vertexSamplingCoordinates);
    glDrawArrays(GL_POINTS, 0, inputTextureSize.width * inputTextureSize.height / (CGFloat)_downsamplingFactor);

    if (histogramType == kGPUImageHistogramRGB)
    {
        [GPUImageContext setActiveShaderProgram:secondFilterProgram];
        
        glVertexAttribPointer(secondFilterPositionAttribute, 4, GL_UNSIGNED_BYTE, 0, ((unsigned int)_downsamplingFactor - 1) * 4, vertexSamplingCoordinates);
        glDrawArrays(GL_POINTS, 0, inputTextureSize.width * inputTextureSize.height / (CGFloat)_downsamplingFactor);

        [GPUImageContext setActiveShaderProgram:thirdFilterProgram];
        
        glVertexAttribPointer(thirdFilterPositionAttribute, 4, GL_UNSIGNED_BYTE, 0, ((unsigned int)_downsamplingFactor - 1) * 4, vertexSamplingCoordinates);
        glDrawArrays(GL_POINTS, 0, inputTextureSize.width * inputTextureSize.height / (CGFloat)_downsamplingFactor);
    }
    
    glDisable(GL_BLEND);
    [firstInputFramebuffer unlock];

    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

#pragma mark -
#pragma mark Accessors

//- (void)setScalingFactor:(CGFloat)newValue;
//{
//    _scalingFactor = newValue;
//    
//    [GPUImageContext useImageProcessingContext];
//    [filterProgram use];
//    glUniform1f(scalingFactorUniform, _scalingFactor);
//}

@end

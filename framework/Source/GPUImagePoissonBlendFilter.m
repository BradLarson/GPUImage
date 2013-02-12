#import "GPUImagePoissonBlendFilter.h"

NSString *const kGPUImagePoissonBlendFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 varying vec2 topTextureCoordinate;
 varying vec2 bottomTextureCoordinate;
 
 varying vec2 textureCoordinate2;
 varying vec2 leftTextureCoordinate2;
 varying vec2 rightTextureCoordinate2;
 varying vec2 topTextureCoordinate2;
 varying vec2 bottomTextureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform lowp float mixturePercent;

 void main()
 {
     vec4 centerColor = texture2D(inputImageTexture, textureCoordinate);
     vec3 bottomColor = texture2D(inputImageTexture, bottomTextureCoordinate).rgb;
     vec3 leftColor = texture2D(inputImageTexture, leftTextureCoordinate).rgb;
     vec3 rightColor = texture2D(inputImageTexture, rightTextureCoordinate).rgb;
     vec3 topColor = texture2D(inputImageTexture, topTextureCoordinate).rgb;

     vec4 centerColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     vec3 bottomColor2 = texture2D(inputImageTexture2, bottomTextureCoordinate2).rgb;
     vec3 leftColor2 = texture2D(inputImageTexture2, leftTextureCoordinate2).rgb;
     vec3 rightColor2 = texture2D(inputImageTexture2, rightTextureCoordinate2).rgb;
     vec3 topColor2 = texture2D(inputImageTexture2, topTextureCoordinate2).rgb;

     vec3 meanColor = (bottomColor + leftColor + rightColor + topColor) / 4.0;
     vec3 diffColor = centerColor.rgb - meanColor;

     vec3 meanColor2 = (bottomColor2 + leftColor2 + rightColor2 + topColor2) / 4.0;
     vec3 diffColor2 = centerColor2.rgb - meanColor2;
     
     vec3 gradColor = (meanColor + diffColor2);
     
	 gl_FragColor = vec4(mix(centerColor.rgb, gradColor, centerColor2.a * mixturePercent), centerColor.a);
 }
);

@implementation GPUImagePoissonBlendFilter

@synthesize mix = _mix;
@synthesize numIterations = _numIterations;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImagePoissonBlendFragmentShaderString]))
    {
		return nil;
    }
    
    mixUniform = [filterProgram uniformIndex:@"mixturePercent"];
    self.mix = 0.5;
    
    self.numIterations = 10;
    
    return self;
}

- (void)setMix:(CGFloat)newValue;
{
    _mix = newValue;
    
    [self setFloat:_mix forUniform:mixUniform program:filterProgram];
}

- (void)initializeSecondOutputTextureIfNeeded;
{
    if ([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage)
    {
        return;
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext useImageProcessingContext];
        
        if (!secondFilterOutputTexture)
        {
            glGenTextures(1, &secondFilterOutputTexture);
            glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    });
}

- (void)deleteOutputTexture;
{
    if (outputTexture)
    {
        glDeleteTextures(1, &outputTexture);
        outputTexture = 0;
    }
    
    if (!([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage))
    {
        if (secondFilterOutputTexture)
        {
            glDeleteTextures(1, &secondFilterOutputTexture);
            secondFilterOutputTexture = 0;
        }
    }
}

- (void)createFilterFBOofSize:(CGSize)currentFBOSize
{    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext useImageProcessingContext];
        
        if (!filterFramebuffer)
        {
            if ([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage)
            {
                preparedToCaptureImage = NO;
                [super createFilterFBOofSize:currentFBOSize];
                preparedToCaptureImage = YES;
            }
            else
            {
                [super createFilterFBOofSize:currentFBOSize];
            }
        }
        
        glGenFramebuffers(1, &secondFilterFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, secondFilterFramebuffer);
        
        if ([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage)
        {
#if defined(__IPHONE_6_0)
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &filterTextureCache);
#else
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &filterTextureCache);
#endif
            
            if (err)
            {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
            }
            
            // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
            
            CFDictionaryRef empty; // empty value for attr value.
            CFMutableDictionaryRef attrs;
            empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
            attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
            
            err = CVPixelBufferCreate(kCFAllocatorDefault, (int)currentFBOSize.width, (int)currentFBOSize.height, kCVPixelFormatType_32BGRA, attrs, &renderTarget);
            if (err)
            {
                NSLog(@"FBO size: %f, %f", currentFBOSize.width, currentFBOSize.height);
                NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
            }
            
            err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault,
                                                                filterTextureCache, renderTarget,
                                                                NULL, // texture attributes
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA, // opengl format
                                                                (int)currentFBOSize.width,
                                                                (int)currentFBOSize.height,
                                                                GL_BGRA, // native iOS format
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &renderTexture);
            if (err)
            {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            CFRelease(attrs);
            CFRelease(empty);
            glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
            secondFilterOutputTexture = CVOpenGLESTextureGetName(renderTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
            
            [self notifyTargetsAboutNewOutputTexture];
        }
        else
        {
            [self initializeSecondOutputTextureIfNeeded];
            glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
            //            if ([self providesMonochromeOutput] && [GPUImageOpenGLESContext deviceSupportsRedTextures])
            //            {
            //                glTexImage2D(GL_TEXTURE_2D, 0, GL_RG_EXT, (int)currentFBOSize.width, (int)currentFBOSize.height, 0, GL_RG_EXT, GL_UNSIGNED_BYTE, 0);
            //            }
            //            else
            //            {
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)currentFBOSize.width, (int)currentFBOSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
            //            }
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, secondFilterOutputTexture, 0);
            
            [self notifyTargetsAboutNewOutputTexture];
        }
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
        
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)recreateFilterFBO
{
    cachedMaximumOutputSize = CGSizeZero;
    
    [self destroyFilterFBO];
    [self deleteOutputTexture];
}

- (void)destroyFilterFBO;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext useImageProcessingContext];
        
        if (filterFramebuffer)
        {
            glDeleteFramebuffers(1, &filterFramebuffer);
            filterFramebuffer = 0;
        }
        
        if (secondFilterFramebuffer)
        {
            glDeleteFramebuffers(1, &secondFilterFramebuffer);
            secondFilterFramebuffer = 0;
        }
        
        if (filterTextureCache != NULL)
        {
            CFRelease(renderTarget);
            renderTarget = NULL;
            
            if (renderTexture)
            {
                CFRelease(renderTexture);
                renderTexture = NULL;
            }
            
            CVOpenGLESTextureCacheFlush(filterTextureCache, 0);
            CFRelease(filterTextureCache);
            filterTextureCache = NULL;
        }
    });
}
 
- (void)setSecondFilterFBO;
{
    glBindFramebuffer(GL_FRAMEBUFFER, secondFilterFramebuffer);
}

- (void)setOutputFBO;
{
    if (self.numIterations % 2 == 1) {
        [self setSecondFilterFBO];
    } else {
        [self setFilterFBO];
    }
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    // Run the first stage of the two-pass filter
    [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
    
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates sourceTexture:sourceTexture];
    
    for (int pass = 1; pass < self.numIterations; pass++) {
        
        if (pass % 2 == 0) {
            
            [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
            
            [super renderToTextureWithVertices:vertices textureCoordinates:[[self class] textureCoordinatesForRotation:kGPUImageNoRotation] sourceTexture:secondFilterOutputTexture];
        } else {
            // Run the second stage of the two-pass filter
            [self setSecondFilterFBO];
            
            [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
            
            glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
            glClear(GL_COLOR_BUFFER_BIT);
            
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, outputTexture);
            glUniform1i(filterInputTextureUniform, 2);
            
            glActiveTexture(GL_TEXTURE3);
            glBindTexture(GL_TEXTURE_2D, filterSourceTexture2);
            glUniform1i(filterInputTextureUniform2, 3);
            
            glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
            glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [[self class] textureCoordinatesForRotation:kGPUImageNoRotation]);
            glVertexAttribPointer(filterSecondTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [[self class] textureCoordinatesForRotation:inputRotation2]);
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);            
        }
    }
}

@end
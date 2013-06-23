//  adapted from unitzeroone - http://unitzeroone.com/labs/jfavoronoi/

#import "GPUImageJFAVoronoiFilter.h"

//  The shaders are mostly taken from UnitZeroOne's WebGL example here:
//  http://unitzeroone.com/blog/2011/03/22/jump-flood-voronoi-for-webgl/

NSString *const kGPUImageJFAVoronoiVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform float sampleStep;
 
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 void main()
 {
     gl_Position = position;
     
     vec2 widthStep = vec2(sampleStep, 0.0);
     vec2 heightStep = vec2(0.0, sampleStep);
     vec2 widthHeightStep = vec2(sampleStep);
     vec2 widthNegativeHeightStep = vec2(sampleStep, -sampleStep);
     
     textureCoordinate = inputTextureCoordinate.xy;
     leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
     rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;
     
     topTextureCoordinate = inputTextureCoordinate.xy - heightStep;
     topLeftTextureCoordinate = inputTextureCoordinate.xy - widthHeightStep;
     topRightTextureCoordinate = inputTextureCoordinate.xy + widthNegativeHeightStep;
     
     bottomTextureCoordinate = inputTextureCoordinate.xy + heightStep;
     bottomLeftTextureCoordinate = inputTextureCoordinate.xy - widthNegativeHeightStep;
     bottomRightTextureCoordinate = inputTextureCoordinate.xy + widthHeightStep;
 }
 );

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageJFAVoronoiFragmentShaderString = SHADER_STRING
(
 
 precision highp float;
 
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform vec2 size;
 //varying vec2 textureCoordinate;
 //uniform float sampleStep;
 
 vec2 getCoordFromColor(vec4 color)
{
    float z = color.z * 256.0;
    float yoff = floor(z / 8.0);
    float xoff = mod(z, 8.0);
    float x = color.x*256.0 + xoff*256.0;
    float y = color.y*256.0 + yoff*256.0;
    return vec2(x,y) / size;
}
 
 void main(void) {
     
     vec2 sub;
     vec4 dst;
     vec4 local = texture2D(inputImageTexture, textureCoordinate);
     vec4 sam;
     float l;
     float smallestDist;
     if(local.a == 0.0){
         
         smallestDist = dot(1.0,1.0);
     }else{
         sub = getCoordFromColor(local)-textureCoordinate;
         smallestDist = dot(sub,sub);
     }
     dst = local;
     
     
     sam = texture2D(inputImageTexture, topRightTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, topTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, topLeftTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, bottomRightTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, bottomTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, bottomLeftTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, leftTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, rightTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     gl_FragColor = dst;
 }
);
#else
NSString *const kGPUImageJFAVoronoiFragmentShaderString = SHADER_STRING
( 
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform vec2 size;
 //varying vec2 textureCoordinate;
 //uniform float sampleStep;
 
 vec2 getCoordFromColor(vec4 color)
{
    float z = color.z * 256.0;
    float yoff = floor(z / 8.0);
    float xoff = mod(z, 8.0);
    float x = color.x*256.0 + xoff*256.0;
    float y = color.y*256.0 + yoff*256.0;
    return vec2(x,y) / size;
}
 
 void main(void) {
     
     vec2 sub;
     vec4 dst;
     vec4 local = texture2D(inputImageTexture, textureCoordinate);
     vec4 sam;
     float l;
     float smallestDist;
     if(local.a == 0.0){
         
         smallestDist = dot(1.0,1.0);
     }else{
         sub = getCoordFromColor(local)-textureCoordinate;
         smallestDist = dot(sub,sub);
     }
     dst = local;
     
     
     sam = texture2D(inputImageTexture, topRightTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, topTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, topLeftTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, bottomRightTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, bottomTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, bottomLeftTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, leftTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     sam = texture2D(inputImageTexture, rightTextureCoordinate);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-textureCoordinate);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     gl_FragColor = dst;
 }
);
#endif

@interface GPUImageJFAVoronoiFilter() {
    int currentPass;
}


@end

@implementation GPUImageJFAVoronoiFilter

@synthesize sizeInPixels = _sizeInPixels;

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageJFAVoronoiVertexShaderString fragmentShaderFromString:kGPUImageJFAVoronoiFragmentShaderString]))
    {
        
        NSLog(@"nil returned");
		return nil;
        
    }
    
    sampleStepUniform = [filterProgram uniformIndex:@"sampleStep"];
    sizeUniform = [filterProgram uniformIndex:@"size"];
    //[self disableSecondFrameCheck];
    
    return self;
}

-(void)setSizeInPixels:(CGSize)sizeInPixels {
    _sizeInPixels = sizeInPixels;
    
    //validate that it's a power of 2
    
    float width = log2(sizeInPixels.width);
    float height = log2(sizeInPixels.height);
    
    if (width != height) {
        NSLog(@"Voronoi point texture must be square");
        return;
    }
    if (width != floor(width) || height != floor(height)) {
        NSLog(@"Voronoi point texture must be a power of 2.  Texture size: %f, %f", sizeInPixels.width, sizeInPixels.height);
        return;
    }
    glUniform2f(sizeUniform, _sizeInPixels.width, _sizeInPixels.height);
}

#pragma mark -
#pragma mark Managing the display FBOs


- (void)initializeOutputTextureIfNeeded;
{
    [GPUImageContext useImageProcessingContext];
    
    glActiveTexture(GL_TEXTURE2);
    glGenTextures(1, &outputTexture);
	glBindTexture(GL_TEXTURE_2D, outputTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, self.outputTextureOptions.minFilter);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, self.outputTextureOptions.magFilter);
	// This is necessary for non-power-of-two textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self.outputTextureOptions.wrapS);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self.outputTextureOptions.wrapT);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glGenTextures(1, &secondFilterOutputTexture);
	glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, self.outputTextureOptions.minFilter);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, self.outputTextureOptions.magFilter);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self.outputTextureOptions.wrapS);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self.outputTextureOptions.wrapT);
    glBindTexture(GL_TEXTURE_2D, 0);
}

-(NSUInteger)nextPowerOfTwo:(CGPoint)input {
    NSUInteger val;
    if (input.x > input.y) {
        val = (NSUInteger)input.x;
    } else {
        val = (NSUInteger)input.y;
    }
    
    val--;
    val = (val >> 1) | val;
    val = (val >> 2) | val;
    val = (val >> 4) | val;
    val = (val >> 8) | val;
    val = (val >> 16) | val;
    val++;
    return val;
}

- (void)createFilterFBOofSize:(CGSize)currentFBOSize
{
    
    [self prepareForImageCapture];
    numPasses = (int)log2([self nextPowerOfTwo:CGPointMake(currentFBOSize.width, currentFBOSize.height)]);
    
    if ([GPUImageContext supportsFastTextureUpload] && preparedToCaptureImage)
    {
        //preparedToCaptureImage = NO;
        [super createFilterFBOofSize:currentFBOSize];
        //preparedToCaptureImage = YES;
        
    }
    else
    {
        [super createFilterFBOofSize:currentFBOSize];
        
    }
    
    glGenFramebuffers(1, &secondFilterFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, secondFilterFramebuffer);
    
    if ([GPUImageContext supportsFastTextureUpload] && preparedToCaptureImage)
    {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#if defined(__IPHONE_6_0)
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[GPUImageContext sharedImageProcessingContext] context], NULL, &filterTextureCache);
#else
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageContext sharedImageProcessingContext] context], NULL, &filterTextureCache);
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
                                                            self.outputTextureOptions.internalFormat, // opengl format
                                                            (int)currentFBOSize.width,
                                                            (int)currentFBOSize.height,
                                                            self.outputTextureOptions.format, // native iOS format
                                                            self.outputTextureOptions.type,
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
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self.outputTextureOptions.wrapS);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self.outputTextureOptions.wrapS);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
        
        [self notifyTargetsAboutNewOutputTexture];
#endif
    }
    else
    {
        [self initializeOutputTextureIfNeeded];
        
        glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     self.outputTextureOptions.internalFormat,
                     (int)currentFBOSize.width,
                     (int)currentFBOSize.height,
                     0,
                     self.outputTextureOptions.format,
                     self.outputTextureOptions.type,
                     0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, secondFilterOutputTexture, 0);
        
        [self notifyTargetsAboutNewOutputTexture];
    }
    
    glBindTexture(GL_TEXTURE_2D, outputTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, self.outputTextureOptions.magFilter);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, self.outputTextureOptions.minFilter);
    
    glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, self.outputTextureOptions.magFilter);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, self.outputTextureOptions.minFilter);
    
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    
    glBindTexture(GL_TEXTURE_2D, 0);
}


//we may not need these
- (void)setSecondFilterFBO;
{
    glBindFramebuffer(GL_FRAMEBUFFER, secondFilterFramebuffer);
    //
    //    CGSize currentFBOSize = [self sizeOfFBO];
    //    glViewport(0, 0, (int)currentFBOSize.width, (int)currentFBOSize.height);
}

- (void)setOutputFBO;
{
    if (currentPass % 2 == 1) {
        [self setSecondFilterFBO];
    } else {
        [self setFilterFBO];
    }
    
}


- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    // Run the first stage of the two-pass filter
    [GPUImageContext setActiveShaderProgram:filterProgram];
    currentPass = 0;
    [self setFilterFBO];
    
    glActiveTexture(GL_TEXTURE2);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUniform1f(sampleStepUniform, 0.5);
    
    glUniform2f(sizeUniform, _sizeInPixels.width, _sizeInPixels.height);
    
    glBindTexture(GL_TEXTURE_2D, sourceTexture);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    for (int pass = 1; pass <= numPasses + 1; pass++) {
        currentPass = pass;
        [self setOutputFBO];
        
        //glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE2);
        if (pass % 2 == 0) {
            glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
        } else {
            glBindTexture(GL_TEXTURE_2D, outputTexture);
        }
        glUniform1i(filterInputTextureUniform, 2);
        
        float step = pow(2.0, numPasses - pass) / pow(2.0, numPasses);
        glUniform1f(sampleStepUniform, step);
        glUniform2f(sizeUniform, _sizeInPixels.width, _sizeInPixels.height);
        
        glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
        glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
}

@end

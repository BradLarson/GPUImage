//
//  GPUImageJFAVoroni.m
//  Face Esplode
//
//  Created by Jacob Gundersen on 4/27/12.
//  
//  adapted from unitzeroone - http://unitzeroone.com/labs/jfavoronoi/

#import "GPUImageJFAVoroni.h"

NSString *const kGPUImageJFAVoroniFragmentShaderString = SHADER_STRING
(

 precision highp float;
 
 uniform sampler2D inputImageTexture;
 varying vec2 textureCoordinate;
 uniform float sampleStep;
 
 vec2 getCoordFromColor(vec4 color)
{
    float z = color.z * 256.0;
    float xoff = mod(z,2.0);
    float yoff = ((z - xoff)*.5);
    float x = color.x*256.0 + xoff*256.0;
    float y = color.y*256.0 + yoff*256.0;
    //return vec2(x,y);
    return vec2(x,y) / 256.0;
}
 
 void main(void) {
     vec3 samplePos = vec3(sampleStep,0.0,-sampleStep);
     //vec2 wh = vec2(512.0,512.0);
     vec2 uvIn = textureCoordinate;
     vec2 uv;
     vec2 sub;
     vec4 dst;
     //vec4 local = texture2D(inputImageTexture, uvIn/wh);
     vec4 local = texture2D(inputImageTexture, uvIn);
     vec4 sam;
     float l;
     float smallestDist;
     if(local.a == 0.0){
         //smallestDist = dot(wh,wh);
         smallestDist = dot(1.0,1.0);
     }else{
         sub = getCoordFromColor(local)-uvIn;
         smallestDist = dot(sub,sub);
     }
     dst = local;
     uv = uvIn+samplePos.xx;
     //sam = texture2D(inputImageTexture, uv/wh);
     sam = texture2D(inputImageTexture, uv);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-uvIn);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     uv = uvIn+samplePos.yx;
//     sam = texture2D(inputImageTexture, uv/wh);
     sam = texture2D(inputImageTexture, uv);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-uvIn);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     uv = uvIn+samplePos.zx;
//     sam = texture2D(inputImageTexture, uv/wh);
     sam = texture2D(inputImageTexture, uv);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-uvIn);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     uv = uvIn+samplePos.xy;
//     sam = texture2D(inputImageTexture, uv/wh);
     sam = texture2D(inputImageTexture, uv);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-uvIn);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     
     uv = uvIn+samplePos.zy;
//     sam = texture2D(inputImageTexture, uv/wh);
     sam = texture2D(inputImageTexture, uv);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-uvIn);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     uv = uvIn+samplePos.xz;
//     sam = texture2D(inputImageTexture, uv/wh);
     sam = texture2D(inputImageTexture, uv);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-uvIn);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     uv = uvIn+samplePos.yz;
//     sam = texture2D(inputImageTexture, uv/wh);
     sam = texture2D(inputImageTexture, uv);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-uvIn);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     uv = uvIn+samplePos.zz;
//     sam = texture2D(inputImageTexture, uv/wh);
     sam = texture2D(inputImageTexture, uv);
     if(sam.a == 1.0){
         sub = (getCoordFromColor(sam)-uvIn);
         l = dot(sub,sub);
         if(l < smallestDist){
             smallestDist = l;
             dst = sam;
         }
     }
     gl_FragColor = dst;	
 }
 );

@implementation GPUImageJFAVoroni

@synthesize numPasses;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageJFAVoroniFragmentShaderString]))
    {
        NSLog(@"nil returned");
		return nil;

    }
    
    sampleStepUniform = [filterProgram uniformIndex:@"sampleStep"];
    NSLog(@"setup filter");
    return self;
}

#pragma mark -
#pragma mark Managing the display FBOs


- (void)initializeOutputTexture;
{
    [super initializeOutputTexture];
    
    glGenTextures(1, &secondFilterOutputTexture);
	glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)createFilterFBOofSize:(CGSize)currentFBOSize;
{
    NSLog(@"log %f", log2(256)); 
    numPasses = (int)log2(currentFBOSize.width);
    
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
    
    glGenFramebuffers(1, &secondFilterFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, secondFilterFramebuffer);
    
    if ([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage)
    {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &filterTextureCache);
        if (err) 
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d");
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
            NSAssert(NO, @"Error at CVPixelBufferCreate %d");
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
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d");
        }
        
        CFRelease(attrs);
        CFRelease(empty);
        glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
        secondFilterOutputTexture = CVOpenGLESTextureGetName(renderTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    }
    else
    {
        glBindTexture(GL_TEXTURE_2D, secondFilterOutputTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)currentFBOSize.width, (int)currentFBOSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, secondFilterOutputTexture, 0);
    }
	NSLog(@"doe here");
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
    if (numPasses % 2 == 1) {
        [self setSecondFilterFBO];
    } else {
        [self setFilterFBO];
    }
    
}


- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    // Run the first stage of the two-pass filter
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(sampleStepUniform, 0.5);
    
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates sourceTexture:sourceTexture];
    
    for (int pass = 1; pass <= numPasses + 1; pass++) {
        //NSLog(@"pass %d", pass);
        if (pass % 2 == 0) {
            
            [GPUImageOpenGLESContext useImageProcessingContext];
            [filterProgram use];
            
            float step = pow(2.0, numPasses - pass) / self.sizeOfFBO.width;
            glUniform1f(sampleStepUniform, step);
            
            [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates sourceTexture:secondFilterOutputTexture];
        } else {
            // Run the second stage of the two-pass filter
            [self setSecondFilterFBO];
            
            [filterProgram use];
            
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            glActiveTexture(GL_TEXTURE3);
            glBindTexture(GL_TEXTURE_2D, outputTexture);
            
            glUniform1i(filterInputTextureUniform, 3);	
            
            float step = pow(2.0, numPasses - pass) / self.sizeOfFBO.width;
            glUniform1f(sampleStepUniform, step);
            
            if (filterSourceTexture2 != 0)
            {
                glActiveTexture(GL_TEXTURE4);
                glBindTexture(GL_TEXTURE_2D, filterSourceTexture2);
                
                glUniform1i(filterInputTextureUniform2, 4);
            }
            
            glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
            glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        }
    }
}



@end

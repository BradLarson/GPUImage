#import "GPUImageOpenGLESContext.h"
#import <OpenGLES/EAGLDrawable.h>

@implementation GPUImageOpenGLESContext

// Based on Colin Wheeler's example here: http://cocoasamurai.blogspot.com/2011/04/singletons-your-doing-them-wrong.html
+ (GPUImageOpenGLESContext *)sharedImageProcessingOpenGLESContext;
{
    static dispatch_once_t pred;
    static GPUImageOpenGLESContext *sharedImageProcessingOpenGLESContext = nil;
    
    dispatch_once(&pred, ^{
        sharedImageProcessingOpenGLESContext = [[GPUImageOpenGLESContext alloc] init];
    });
    return sharedImageProcessingOpenGLESContext;
}

+ (void)useImageProcessingContext;
{
    [EAGLContext setCurrentContext:[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context]];
}

+ (GLint)maximumTextureSizeForThisDevice;
{
    GLint maxTextureSize; 
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
    return maxTextureSize;
}

+ (GLint)maximumTextureUnitsForThisDevice;
{
    GLint maxTextureUnits; 
    glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &maxTextureUnits);
    return maxTextureUnits;
}

- (void)presentBufferForDisplay;
{
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark -
#pragma mark Accessors

@synthesize context;

- (EAGLContext *)context;
{
    if (context == nil)
    {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        NSAssert(context != nil, @"Unable to create an OpenGL ES 2.0 context. The GPUImage framework requires OpenGL ES 2.0 support to work.");
        [EAGLContext setCurrentContext:context];
        
        // Set up a few global settings for the image processing pipeline
        glEnable(GL_TEXTURE_2D);
        glDisable(GL_DEPTH_TEST);
    }
    
    return context;
}


@end

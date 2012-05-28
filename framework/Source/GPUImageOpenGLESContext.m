#import "GPUImageOpenGLESContext.h"
#import <OpenGLES/EAGLDrawable.h>
#import <AVFoundation/AVFoundation.h>

@implementation GPUImageOpenGLESContext

@synthesize context = _context;

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
    EAGLContext *imageProcessingContext = [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
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

+ (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize;
{
    GLint maxTextureSize = [self maximumTextureSizeForThisDevice]; 
    if ( (inputSize.width < maxTextureSize) && (inputSize.height < maxTextureSize) )
    {
        return inputSize;
    }
    
    CGSize adjustedSize;
    if (inputSize.width > inputSize.height)
    {
        adjustedSize.width = (CGFloat)maxTextureSize;
        adjustedSize.height = ((CGFloat)maxTextureSize / inputSize.width) * inputSize.height;
    }
    else
    {
        adjustedSize.height = (CGFloat)maxTextureSize;
        adjustedSize.width = ((CGFloat)maxTextureSize / inputSize.height) * inputSize.width;
    }

    return adjustedSize;
}

- (void)presentBufferForDisplay;
{
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark -
#pragma mark Manage fast texture upload

+ (BOOL)supportsFastTextureUpload;
{
    return (CVOpenGLESTextureCacheCreate != NULL);
}

#pragma mark -
#pragma mark Accessors

- (EAGLContext *)context;
{
    if (_context == nil)
    {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        NSAssert(_context != nil, @"Unable to create an OpenGL ES 2.0 context. The GPUImage framework requires OpenGL ES 2.0 support to work.");
        [EAGLContext setCurrentContext:_context];
        
        // Set up a few global settings for the image processing pipeline
        glDisable(GL_DEPTH_TEST);
    }
    
    return _context;
}


@end

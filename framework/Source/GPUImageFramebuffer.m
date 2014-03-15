#import "GPUImageFramebuffer.h"
#import "GPUImageOutput.h"

@interface GPUImageFramebuffer()
{
    GLuint framebuffer;
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
#else
#endif
    NSUInteger framebufferReferenceCount;
    BOOL referenceCountingDisabled;
}

- (void)generateFramebuffer;
- (void)generateTexture;
- (void)destroyFramebuffer;

@end

@implementation GPUImageFramebuffer

@synthesize size = _size;
@synthesize textureOptions = _textureOptions;
@synthesize texture = _texture;
@synthesize missingFramebuffer = _missingFramebuffer;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithSize:(CGSize)framebufferSize textureOptions:(GPUTextureOptions)fboTextureOptions onlyTexture:(BOOL)onlyGenerateTexture;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    _textureOptions = fboTextureOptions;
    _size = framebufferSize;
    framebufferReferenceCount = 0;
    referenceCountingDisabled = NO;
    _missingFramebuffer = onlyGenerateTexture;

    NSLog(@"Creating framebuffer: %@ at size %f, %f", self, _size.width, _size.height);

    if (_missingFramebuffer)
    {
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageContext useImageProcessingContext];
            [self generateTexture];
        });
    }
    else
    {
        [self generateFramebuffer];
    }
    return self;
}

- (id)initWithSize:(CGSize)framebufferSize;
{
    GPUTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;

    if (!(self = [self initWithSize:framebufferSize textureOptions:defaultTextureOptions onlyTexture:NO]))
    {
		return nil;
    }

    return self;
}

- (void)dealloc
{
    NSLog(@"Destroying framebuffer: %@ at size %f, %f", self, _size.width, _size.height);

    [self destroyFramebuffer];
}

#pragma mark -
#pragma mark Internal

- (void)generateTexture;
{
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _textureOptions.magFilter);
    // This is necessary for non-power-of-two textures
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
    
    // TODO: Handle mipmaps
}

- (void)generateFramebuffer;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];

        [self generateTexture];
        
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        
        // By default, all framebuffers on iOS 5.0+ devices are backed by texture caches, using one shared cache
        if ([GPUImageContext supportsFastTextureUpload])
        {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            CVOpenGLESTextureCacheRef coreVideoTextureCache = [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache];
            // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
            
            CFDictionaryRef empty; // empty value for attr value.
            CFMutableDictionaryRef attrs;
            empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
            attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
            
            CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)_size.width, (int)_size.height, kCVPixelFormatType_32BGRA, attrs, &renderTarget);
            if (err)
            {
                NSLog(@"FBO size: %f, %f", _size.width, _size.height);
                NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
            }
            
            err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, coreVideoTextureCache, renderTarget,
                                                                NULL, // texture attributes
                                                                GL_TEXTURE_2D,
                                                                _textureOptions.internalFormat, // opengl format
                                                                (int)_size.width,
                                                                (int)_size.height,
                                                                _textureOptions.format, // native iOS format
                                                                _textureOptions.type,
                                                                0,
                                                                &renderTexture);
            if (err)
            {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            CFRelease(attrs);
            CFRelease(empty);
            
            glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
            _texture = CVOpenGLESTextureGetName(renderTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
            
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
#endif
        }
        else
        {
            glBindTexture(GL_TEXTURE_2D, _texture);
            
            glTexImage2D(GL_TEXTURE_2D, 0, _textureOptions.internalFormat, (int)_size.width, (int)_size.height, 0, _textureOptions.format, _textureOptions.type, 0);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _texture, 0);
        }
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        NSLog(@"Framebuffer texture: %d", _texture);
        
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)destroyFramebuffer;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        glDeleteFramebuffers(1, &framebuffer);
        framebuffer = 0;
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        if (renderTarget)
        {
            CFRelease(renderTarget);
            renderTarget = NULL;
        }
        
        if (renderTexture)
        {
            CFRelease(renderTexture);
            renderTexture = NULL;
        }
        
#endif
    });
}

#pragma mark -
#pragma mark Usage

- (void)activateFramebuffer;
{
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glViewport(0, 0, (int)_size.width, (int)_size.height);
}

#pragma mark -
#pragma mark Reference counting

- (void)lock;
{
    if (referenceCountingDisabled)
    {
        return;
    }
    
    framebufferReferenceCount++;
}

- (void)unlock;
{
    if (referenceCountingDisabled)
    {
        return;
    }

    NSAssert(framebufferReferenceCount > 0, @"Tried to overrelease a framebuffer");
    framebufferReferenceCount--;
    if (framebufferReferenceCount < 1)
    {
        [[GPUImageContext sharedFramebufferCache] returnFramebufferToCache:self];
    }
}

- (void)clearAllLocks;
{
    framebufferReferenceCount = 0;
}

- (void)disableReferenceCounting;
{
    referenceCountingDisabled = YES;
}

- (void)enableReferenceCounting;
{
    referenceCountingDisabled = NO;
}
@end

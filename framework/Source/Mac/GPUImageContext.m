#import "GPUImageContext.h"
#import <AVFoundation/AVFoundation.h>

@interface GPUImageContext()
{
    NSMutableDictionary *shaderProgramCache;
    CGLShareGroupObj *_sharegroup;
}

@end

@implementation GPUImageContext

@synthesize context = _context;
@synthesize currentShaderProgram = _currentShaderProgram;
@synthesize contextQueue = _contextQueue;
@synthesize framebufferCache = _framebufferCache;

static void *openGLESContextQueueKey;

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }

	openGLESContextQueueKey = &openGLESContextQueueKey;
    _contextQueue = dispatch_queue_create("com.sunsetlakesoftware.GPUImage.openGLESContextQueue", NULL);
	dispatch_queue_set_specific(_contextQueue, openGLESContextQueueKey, (__bridge void *)self, NULL);
    shaderProgramCache = [[NSMutableDictionary alloc] init];
    
    return self;
}

+ (void *)contextKey {
	return openGLESContextQueueKey;
}

// Based on Colin Wheeler's example here: http://cocoasamurai.blogspot.com/2011/04/singletons-your-doing-them-wrong.html
+ (GPUImageContext *)sharedImageProcessingContext;
{
    static dispatch_once_t pred;
    static GPUImageContext *sharedImageProcessingContext = nil;
    
    dispatch_once(&pred, ^{
        sharedImageProcessingContext = [[[self class] alloc] init];
    });
    return sharedImageProcessingContext;
}

+ (dispatch_queue_t)sharedContextQueue;
{
    return [[self sharedImageProcessingContext] contextQueue];
}

+ (GPUImageFramebufferCache *)sharedFramebufferCache;
{
    return [[self sharedImageProcessingContext] framebufferCache];
}

+ (void)useImageProcessingContext;
{
    NSOpenGLContext *imageProcessingContext = [[GPUImageContext sharedImageProcessingContext] context];
    if ([NSOpenGLContext currentContext] != imageProcessingContext)
    {
        [imageProcessingContext makeCurrentContext];
    }
}

+ (void)setActiveShaderProgram:(GLProgram *)shaderProgram;
{
    GPUImageContext *sharedContext = [GPUImageContext sharedImageProcessingContext];
    NSOpenGLContext *imageProcessingContext = [sharedContext context];
    if ([NSOpenGLContext currentContext] != imageProcessingContext)
    {
        [imageProcessingContext makeCurrentContext];
    }
    
    if (sharedContext.currentShaderProgram != shaderProgram)
    {
        sharedContext.currentShaderProgram = shaderProgram;
        [shaderProgram use];
    }
}

+ (GLint)maximumTextureSizeForThisDevice;
{
    static dispatch_once_t pred;
    static GLint maxTextureSize = 0;
    
    dispatch_once(&pred, ^{
        [self useImageProcessingContext];
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
    });
    
    return maxTextureSize;
}

+ (GLint)maximumTextureUnitsForThisDevice;
{
    GLint maxTextureUnits; 
    glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &maxTextureUnits);
    return maxTextureUnits;
}

+ (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
{
    static dispatch_once_t pred;
    static NSArray *extensionNames = nil;

    // Cache extensions for later quick reference, since this won't change for a given device
    dispatch_once(&pred, ^{
        [GPUImageContext useImageProcessingContext];
        NSString *extensionsString = [NSString stringWithCString:(const char *)glGetString(GL_EXTENSIONS) encoding:NSASCIIStringEncoding];
        extensionNames = [extensionsString componentsSeparatedByString:@" "];
    });

    return [extensionNames containsObject:extension];
}

+ (BOOL)deviceSupportsFramebufferReads;
{
    return NO;
}

// http://www.khronos.org/registry/gles/extensions/EXT/EXT_texture_rg.txt

+ (BOOL)deviceSupportsRedTextures;
{
    static dispatch_once_t pred;
    static BOOL supportsRedTextures = NO;
    
    dispatch_once(&pred, ^{
        supportsRedTextures = [GPUImageContext deviceSupportsOpenGLESExtension:@"GL_EXT_texture_rg"];
    });
    
    return supportsRedTextures;
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
    [self.context flushBuffer];
}

- (GLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;
{
    NSString *lookupKeyForShaderProgram = [NSString stringWithFormat:@"V: %@ - F: %@", vertexShaderString, fragmentShaderString];
    GLProgram *programFromCache = [shaderProgramCache objectForKey:lookupKeyForShaderProgram];

    if (programFromCache == nil)
    {
        programFromCache = [[GLProgram alloc] initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        [shaderProgramCache setObject:programFromCache forKey:lookupKeyForShaderProgram];
    }
    
    return programFromCache;
}

- (void)useSharegroup:(CGLShareGroupObj *)sharegroup;
{
    NSAssert(_context == nil, @"Unable to use a share group when the context has already been created. Call this method before you use the context for the first time.");
    
    _sharegroup = sharegroup;
}

- (NSOpenGLContext *)createContext;
{
    NSOpenGLPixelFormatAttribute pixelFormatAttributes[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated, 0,
        0
    };
    
    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes];
	if (pixelFormat == nil)
	{
		NSLog(@"Error: No appropriate pixel format found");
	}
    // TODO: Take into account the sharegroup
    NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];

    NSAssert(context != nil, @"Unable to create an OpenGL context. The GPUImage framework requires OpenGL support to work.");
    return context;
}


#pragma mark -
#pragma mark Manage fast texture upload

+ (BOOL)supportsFastTextureUpload;
{
    // This may need to be redone to account for the Mac's accelerated data transfer methods
    return NO;
}

#pragma mark -
#pragma mark Accessors

- (NSOpenGLContext *)context;
{
    if (_context == nil)
    {
        _context = [self createContext];
        [_context makeCurrentContext];

        // Set up a few global settings for the image processing pipeline
        glDisable(GL_DEPTH_TEST);
        glEnable(GL_TEXTURE_2D);
    }
    
    return _context;
}

- (GPUImageFramebufferCache *)framebufferCache;
{
    if (_framebufferCache == nil)
    {
        _framebufferCache = [[GPUImageFramebufferCache alloc] init];
    }
    
    return _framebufferCache;
}

@end

#import "GPUImageFramebufferCache.h"

@interface GPUImageFramebufferCache()
{
    NSCache *framebufferCache;
    NSMutableDictionary *framebufferTypeCounts;
}

- (NSString *)hashForSize:(CGSize)size textureOptions:(GPUTextureOptions)textureOptions;

@end


@implementation GPUImageFramebufferCache

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    framebufferCache = [[NSCache alloc] init];
    framebufferTypeCounts = [[NSMutableDictionary alloc] init];
    
    return self;
}

#pragma mark -
#pragma mark Framebuffer management

- (NSString *)hashForSize:(CGSize)size textureOptions:(GPUTextureOptions)textureOptions;
{
    return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
}

- (GPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(GPUTextureOptions)textureOptions;
{
    NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:textureOptions];
    NSNumber *numberOfMatchingTexturesInCache = [framebufferTypeCounts objectForKey:lookupHash];
    NSInteger numberOfMatchingTextures = [numberOfMatchingTexturesInCache integerValue];
    GPUImageFramebuffer *framebufferFromCache = nil;
    
    if ([numberOfMatchingTexturesInCache integerValue] < 1)
    {
        NSLog(@"Nothing found for hash: %@", lookupHash);
        // Nothing in the cache, create a new framebuffer to use
        framebufferFromCache = [[GPUImageFramebuffer alloc] initWithSize:framebufferSize textureOptions:textureOptions];
    }
    else
    {
        NSLog(@"Existing cached textures for hash: %@", lookupHash);

        // Something found, pull the old framebuffer and decrement the count
        NSInteger currentTextureID = (numberOfMatchingTextures - 1);
        while ((framebufferFromCache == nil) && (currentTextureID >= 0))
        {
            NSString *textureHash = [NSString stringWithFormat:@"%@-%d", lookupHash, currentTextureID];
            NSLog(@"Looking up texture hash of %@", textureHash);
//            NSLog(@"Cache size: %d", [framebufferCache countLimit]);
            framebufferFromCache = [framebufferCache objectForKey:textureHash];
            // Test the values in the cache first, to see if they got invalidated behind our back
            if (framebufferFromCache != nil)
            {
                NSLog(@"Withdrawing texture hash of %@", textureHash);
                // Withdraw this from the cache while it's in use
                [framebufferCache removeObjectForKey:textureHash];
            }
            currentTextureID--;
        }
        
        currentTextureID++;
        NSLog(@"Setting new count to %d for hash: %@", currentTextureID, lookupHash);

        [framebufferTypeCounts setObject:[NSNumber numberWithInteger:currentTextureID] forKey:lookupHash];
        
        if (framebufferFromCache == nil)
        {
            NSLog(@"Cached textures were nil for hash: %@", lookupHash);

            framebufferFromCache = [[GPUImageFramebuffer alloc] initWithSize:framebufferSize textureOptions:textureOptions];

        }
    }

    [framebufferFromCache lock];
    return framebufferFromCache;
}

- (GPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize;
{
    GPUTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;
    
    return [self fetchFramebufferForSize:framebufferSize textureOptions:defaultTextureOptions];
}

- (void)returnFramebufferToCache:(GPUImageFramebuffer *)framebuffer;
{
    [framebuffer clearAllLocks];
    
    CGSize framebufferSize = framebuffer.size;
    GPUTextureOptions framebufferTextureOptions = framebuffer.textureOptions;
    NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:framebufferTextureOptions];
    NSNumber *numberOfMatchingTexturesInCache = [framebufferTypeCounts objectForKey:lookupHash];
    NSInteger numberOfMatchingTextures = [numberOfMatchingTexturesInCache integerValue];

    NSString *textureHash = [NSString stringWithFormat:@"%@-%d", lookupHash, numberOfMatchingTextures];
    
    NSLog(@"Returning framebuffer: %@ with hash: %@", framebuffer, textureHash);
    [framebufferCache setObject:framebuffer forKey:textureHash cost:round(framebufferSize.width * framebufferSize.height * 4.0)];
//    [framebufferCache setObject:framebuffer forKey:textureHash];
    [framebufferTypeCounts setObject:[NSNumber numberWithInteger:(numberOfMatchingTextures + 1)] forKey:lookupHash];
}

- (void)purgeAllUnassignedFramebuffers;
{
    [framebufferCache removeAllObjects];
    [framebufferTypeCounts removeAllObjects];
}

@end

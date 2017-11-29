#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImageFramebuffer.h"


// GPU: 这个就是一个GPUFramebuffer 对象缓存池,没有就重新创建一个framebuffer 都放到这个池;下次直接从这里面取
@interface GPUImageFramebufferCache : NSObject

// Framebuffer management
- (GPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(GPUTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;
- (GPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize onlyTexture:(BOOL)onlyTexture;
- (void)returnFramebufferToCache:(GPUImageFramebuffer *)framebuffer;
- (void)purgeAllUnassignedFramebuffers;
- (void)addFramebufferToActiveImageCaptureList:(GPUImageFramebuffer *)framebuffer;
- (void)removeFramebufferFromActiveImageCaptureList:(GPUImageFramebuffer *)framebuffer;

@end

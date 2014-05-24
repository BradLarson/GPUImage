#import <Foundation/Foundation.h>
//#import <QuartzCore/QuartzCore.h>

@class GLProgram;
@class GPUImageFramebuffer;
@class GPUImageFramebufferCache;

#define GPUImageRotationSwapsWidthAndHeight(rotation) (((rotation) == kGPUImageRotateLeft) || ((rotation) == kGPUImageRotateRight) || ((rotation) == kGPUImageRotateRightFlipVertical) )

typedef enum { kGPUImageNoRotation, kGPUImageRotateLeft, kGPUImageRotateRight, kGPUImageFlipVertical, kGPUImageFlipHorizonal, kGPUImageRotateRightFlipVertical, kGPUImageRotateRightFlipHorizontal, kGPUImageRotate180 } GPUImageRotationMode;

@interface GPUImageContext : NSObject

@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(readwrite, retain, nonatomic) GLProgram *currentShaderProgram;
@property(readonly, retain, nonatomic) NSOpenGLContext *context;
@property(readonly) GPUImageFramebufferCache *framebufferCache;

+ (void *)contextKey;
+ (GPUImageContext *)sharedImageProcessingContext;
+ (dispatch_queue_t)sharedContextQueue;
+ (GPUImageFramebufferCache *)sharedFramebufferCache;
+ (void)useImageProcessingContext;
+ (void)setActiveShaderProgram:(GLProgram *)shaderProgram;
+ (GLint)maximumTextureSizeForThisDevice;
+ (GLint)maximumTextureUnitsForThisDevice;
+ (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
+ (BOOL)deviceSupportsRedTextures;
+ (BOOL)deviceSupportsFramebufferReads;
+ (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize;

- (void)presentBufferForDisplay;
- (GLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

- (void)useSharegroup:(CGLShareGroupObj *)sharegroup;

// Manage fast texture upload
+ (BOOL)supportsFastTextureUpload;

@end

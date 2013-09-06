#import <Foundation/Foundation.h>
#import "GPUImageContext.h"

struct GPUByteColorVector {
    GLubyte red;
    GLubyte green;
    GLubyte blue;
    GLubyte alpha;
};
typedef struct GPUByteColorVector GPUByteColorVector;

@protocol GPUImageRawDataProcessor;

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
@interface GPUImageRawDataOutput : NSObject <GPUImageInput> {
    CGSize imageSize;
    CVOpenGLESTextureCacheRef rawDataTextureCache;
    CVPixelBufferRef renderTarget;
    GPUImageRotationMode inputRotation;
    BOOL outputBGRA;
    CVOpenGLESTextureRef renderTexture;
    
    __unsafe_unretained id<GPUImageTextureDelegate> textureDelegate;
}
#else
@interface GPUImageRawDataOutput : NSObject <GPUImageInput> {
    CGSize imageSize;
    CVOpenGLTextureCacheRef rawDataTextureCache;
    CVPixelBufferRef renderTarget;
    GPUImageRotationMode inputRotation;
    BOOL outputBGRA;
    CVOpenGLTextureRef renderTexture;
    
    __unsafe_unretained id<GPUImageTextureDelegate> textureDelegate;
}
#endif

@property(readonly) GLubyte *rawBytesForImage;
@property(nonatomic, copy) void(^newFrameAvailableBlock)(void);
@property(nonatomic) BOOL enabled;

// Initialization and teardown
- (id)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat;

// Data access
- (GPUByteColorVector)colorAtLocation:(CGPoint)locationInImage;
- (NSUInteger)bytesPerRowInOutput;

- (void)setImageSize:(CGSize)newImageSize;

@end

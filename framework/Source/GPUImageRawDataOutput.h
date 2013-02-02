#import <Foundation/Foundation.h>
#import "GPUImageOpenGLESContext.h"

struct GPUByteColorVector {
    GLubyte red;
    GLubyte green;
    GLubyte blue;
    GLubyte alpha;
};
typedef struct GPUByteColorVector GPUByteColorVector;

@protocol GPUImageRawDataProcessor;

@interface GPUImageRawDataOutput : NSObject <GPUImageInput> {
    CGSize imageSize;
    CVOpenGLESTextureCacheRef rawDataTextureCache;
    CVPixelBufferRef renderTarget;
    GPUImageRotationMode inputRotation;
    BOOL outputBGRA;
    CVOpenGLESTextureRef renderTexture;
    
    __unsafe_unretained id<GPUImageTextureDelegate> textureDelegate;
}

@property(readonly) GLubyte *rawBytesForImage;
@property(nonatomic, copy) void(^newFrameAvailableBlock)(void);
@property(nonatomic) BOOL enabled;

// Initialization and teardown
- (id)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat;

// Data access
- (GPUByteColorVector)colorAtLocation:(CGPoint)locationInImage;
- (NSUInteger)bytesPerRowInOutput;

@end

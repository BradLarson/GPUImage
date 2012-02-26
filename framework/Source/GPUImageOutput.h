#import "GPUImageOpenGLESContext.h"
#import "GLProgram.h"

@interface GPUImageOutput : NSObject
{
    NSMutableArray *targets, *targetTextureIndices;
    
    GLuint outputTexture;
    CGSize inputTextureSize, cachedMaximumOutputSize;
}

@property(readwrite, nonatomic) BOOL shouldSmoothlyScaleOutput;

// Managing targets
- (void)addTarget:(id<GPUImageInput>)newTarget;
- (void)removeTarget:(id<GPUImageInput>)targetToRemove;
- (void)removeAllTargets;

// Manage the output texture
- (void)initializeOutputTexture;
- (void)deleteOutputTexture;

@end

#import <UIKit/UIKit.h>

#import "GPUImageOpenGLESContext.h"
#import "GLProgram.h"

void runOnMainQueueWithoutDeadlocking(void (^block)(void));

@class GPUImageMovieWriter;

@interface GPUImageOutput : NSObject
{
    NSMutableArray *targets, *targetTextureIndices;
    
    GLuint outputTexture;
    CGSize inputTextureSize, cachedMaximumOutputSize;
    id<GPUImageInput> targetToIgnoreForUpdates;
    
    BOOL overrideInputSize;
}

@property(readwrite, nonatomic) BOOL shouldSmoothlyScaleOutput;
@property(readwrite, nonatomic) BOOL shouldIgnoreUpdatesToThisTarget;
@property(readwrite, nonatomic, retain) GPUImageMovieWriter *audioEncodingTarget;

// Managing targets
- (void)setInputTextureForTarget:(id<GPUImageInput>)target atIndex:(NSInteger)inputTextureIndex;
- (void)addTarget:(id<GPUImageInput>)newTarget;
- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
- (void)removeTarget:(id<GPUImageInput>)targetToRemove;
- (void)removeAllTargets;

// Manage the output texture
- (void)initializeOutputTexture;
- (void)deleteOutputTexture;
- (void)forceProcessingAtSize:(CGSize)frameSize;

// Still image processing
- (UIImage *)imageFromCurrentlyProcessedOutput;
- (UIImage *)imageFromCurrentlyProcessedOutputWithOrientation:(UIImageOrientation)imageOrientation;
- (UIImage *)imageByFilteringImage:(UIImage *)imageToFilter;

@end

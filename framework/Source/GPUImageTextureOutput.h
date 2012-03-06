#import <Foundation/Foundation.h>
#import "GPUImageOpenGLESContext.h"

@protocol GPUImageTextureOutputDelegate;

@interface GPUImageTextureOutput : NSObject <GPUImageInput>

@property(readwrite, unsafe_unretained, nonatomic) id<GPUImageTextureOutputDelegate> delegate;
@property(readonly) GLint texture;

@end

@protocol GPUImageTextureOutputDelegate
- (void)newFrameReadyFromTextureOutput:(GPUImageTextureOutput *)callbackTextureOutput;
@end
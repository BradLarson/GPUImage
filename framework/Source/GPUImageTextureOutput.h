#import <Foundation/Foundation.h>
#import "GPUImageContext.h"

@protocol GPUImageTextureOutputDelegate;

@interface GPUImageTextureOutput : NSObject <GPUImageInput>
{
    GPUImageFramebuffer *firstInputFramebuffer;
}

@property(readwrite, unsafe_unretained, nonatomic) id<GPUImageTextureOutputDelegate> delegate;
@property(readonly) GLuint texture;
@property(nonatomic) BOOL enabled;

- (void)doneWithTexture;

@end

@protocol GPUImageTextureOutputDelegate
- (void)newFrameReadyFromTextureOutput:(GPUImageTextureOutput *)callbackTextureOutput;
@end

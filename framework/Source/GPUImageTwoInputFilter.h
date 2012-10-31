#import "GPUImageFilter.h"

extern NSString *const kGPUImageTwoInputTextureVertexShaderString;

@interface GPUImageTwoInputFilter : GPUImageFilter
{
    GLint filterSecondTextureCoordinateAttribute;
    GLint filterInputTextureUniform2;
    GPUImageRotationMode inputRotation2;
    GLuint filterSourceTexture2;
    CMTime firstFrameTime, secondFrameTime;
    
    BOOL hasSetFirstTexture, hasReceivedFirstFrame, hasReceivedSecondFrame, firstFrameWasVideo, secondFrameWasVideo;
    BOOL firstFrameCheckDisabled, secondFrameCheckDisabled;
    
    __unsafe_unretained id<GPUImageTextureDelegate> secondTextureDelegate;
}

- (void)disableFirstFrameCheck;
- (void)disableSecondFrameCheck;

@end

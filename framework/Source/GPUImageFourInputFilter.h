#import "GPUImageThreeInputFilter.h"

extern NSString *const kGPUImageFourInputTextureVertexShaderString;

@interface GPUImageFourInputFilter : GPUImageThreeInputFilter
{
    GPUImageFramebuffer *fourthInputFramebuffer;

    GLint filterFourthTextureCoordinateAttribute;
    GLint filterInputTextureUniform4;
    GPUImageRotationMode inputRotation4;
    GLuint filterSourceTexture4;
    CMTime fourthFrameTime;
    
    BOOL hasSetThirdTexture, hasReceivedFourthFrame, fourthFrameWasVideo;
    BOOL fourthFrameCheckDisabled;
}

- (void)disableFourthFrameCheck;

@end

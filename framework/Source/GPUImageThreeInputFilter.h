#import "GPUImageTwoInputFilter.h"

extern NSString *const kGPUImageThreeInputTextureVertexShaderString;

@interface GPUImageThreeInputFilter : GPUImageTwoInputFilter
{
    GPUImageFramebuffer *thirdInputFramebuffer;

    GLint filterThirdTextureCoordinateAttribute;
    GLint filterInputTextureUniform3;
    GPUImageRotationMode inputRotation3;
    GLuint filterSourceTexture3;
    CMTime thirdFrameTime;
    
    BOOL hasSetSecondTexture, hasReceivedThirdFrame, thirdFrameWasVideo;
    BOOL thirdFrameCheckDisabled;
    
    BOOL secondTextureCompleted;
    BOOL thirdTextureCompleted;
    
}

- (void) setInputCompleted:(BOOL)completed atIndex:(NSInteger)textureIndex;
- (void)disableThirdFrameCheck;

@end

#import "GPUImageTwoInputFilter.h"

extern NSString *const kGPUImageThreeInputTextureVertexShaderString;

@class GPUImageMovie;

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
    
    NSInteger numberOfFrameOne;
    NSInteger numberOfFrameTwo;
    NSInteger numberOfFrameThree;
        
    GPUImageMovie *thirdImageMovie;
    
}

- (void) setThirdImageMovie:(GPUImageMovie *)imageMovie;
- (void)disableThirdFrameCheck;

@end

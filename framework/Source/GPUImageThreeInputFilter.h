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
    BOOL secondTextureCompleted;
    BOOL thirdTextureCompleted;
    
}

- (void) setThirdImageMovie:(GPUImageMovie *)imageMovie;
- (void) setInputCompleted:(BOOL)completed atIndex:(NSInteger)textureIndex;
- (void)disableThirdFrameCheck;

@end

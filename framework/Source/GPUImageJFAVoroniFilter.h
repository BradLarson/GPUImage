#import "GPUImageTwoInputFilter.h"

@interface GPUImageJFAVoroniFilter : GPUImageTwoInputFilter 
{
    GLuint secondFilterOutputTexture;
    GLuint secondFilterFramebuffer;
    GLint sampleStepUniform;
    GLint sizeUniform;
    NSUInteger numPasses;
    
}

@property (nonatomic, readwrite) CGSize sizeInPixels;

@end

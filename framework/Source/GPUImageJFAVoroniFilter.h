<<<<<<< HEAD
#import "GPUImageFilter.h"

@interface GPUImageJFAVoroniFilter : GPUImageFilter 
=======
#import "GPUImageTwoInputFilter.h"

@interface GPUImageJFAVoroniFilter : GPUImageTwoInputFilter 
>>>>>>> bde8ee034d6d737ebd18a4c62fe09d3c22af94c3
{
    GLuint secondFilterOutputTexture;
    GLuint secondFilterFramebuffer;
    
    
    GLint sampleStepUniform;
    GLint sizeUniform;
    NSUInteger numPasses;
    
}

@property (nonatomic, readwrite) CGSize sizeInPixels;

@end

//
//  GPUImageJFAVoroni.h

//  The shaders are mostly taken from UnitZeroOne's WebGL example here:  
//  http://unitzeroone.com/blog/2011/03/22/jump-flood-voronoi-for-webgl/

#import "GPUImageTwoInputFilter.h"

@interface GPUImageJFAVoroniFilter : GPUImageTwoInputFilter {
    GLuint secondFilterOutputTexture;
    GLuint secondFilterFramebuffer;
    GLint sampleStepUniform;
    GLint sizeUniform;
    NSUInteger numPasses;
    
}

@property (nonatomic, readwrite) CGSize sizeInPixels;

@end

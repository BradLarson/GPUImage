//
//  GPUImageJFAVoroni.h
//  Face Esplode
//
//  Created by Jacob Gundersen on 4/27/12.
//  The shaders are mostly taken from UnitZeroOne's WebGL example here:  
//  http://unitzeroone.com/blog/2011/03/22/jump-flood-voronoi-for-webgl/

#import "GPUImageFilter.h"

@interface GPUImageJFAVoroni : GPUImageFilter {
    GLuint secondFilterOutputTexture;
    GLuint secondFilterFramebuffer;
    GLint sampleStepUniform;
}

@property (nonatomic, assign) NSUInteger numPasses;

@end

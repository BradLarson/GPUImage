//
//  GPUImageJFAVoroni.h
//  Face Esplode
//
//  Created by Jacob Gundersen on 4/27/12.
//  Copyright (c) 2012 Interrobang Software LLC. All rights reserved.
//

#import "GPUImageFilter.h"

@interface GPUImageJFAVoroni : GPUImageFilter {
    GLuint secondFilterOutputTexture;
    GLuint secondFilterFramebuffer;
    GLint sampleStepUniform;
}

@property (nonatomic, assign) NSUInteger numPasses;

@end

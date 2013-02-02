//
//  GPUImagePoissonBlendFilter.h
//  GPUImage
//
//  Created by Ian Simon on 1/29/13.
//  Copyright (c) 2013 Brad Larson. All rights reserved.
//

#import "GPUImageTwoInputCrossTextureSamplingFilter.h"
#import "GPUImageFilterGroup.h"

@interface GPUImagePoissonBlendFilter : GPUImageTwoInputCrossTextureSamplingFilter
{
    GLint mixUniform;
    
    GLuint secondFilterOutputTexture;
    GLuint secondFilterFramebuffer;
}

// Mix ranges from 0.0 (only image 1) to 1.0 (only image 2 gradients), with 1.0 as the normal level
@property(readwrite, nonatomic) CGFloat mix;

// The number of times to propagate the gradients.
// Crank this up to 100 or even 1000 if you want to get anywhere near convergence.  Yes, this will be slow.
@property(readwrite, nonatomic) NSUInteger numIterations;

@end
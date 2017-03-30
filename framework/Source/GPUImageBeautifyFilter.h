//
//  GPUImageBeautyFilter.h
//  GPUImagePractice
//
//  Created by qq on 29/3/2017.
//  Copyright © 2017 GitHub. All rights reserved.
//

#import "GPUImageFilter.h"

@interface GPUImageBeautifyFilter : GPUImageFilter {
    GLint singleStepOffsetUniform;
    GPUVector2 singleStepOffset;
}

- (void)setXStep:(float)xStep YStep:(float)yStep;

@end


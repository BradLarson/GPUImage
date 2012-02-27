//
//  GPUImageGaussianBlurFilter.h
//  GPUImage
//
//  Created by Keita Kobayashi on 2/27/12.
//  Copyright (c) 2012 Brad Larson. All rights reserved.
//

#import "GPUImageFilter.h"

@interface GPUImageGaussianBlurFilter : GPUImageFilter {
    GLint blurSizeUniform;
    
    __strong GPUImageFilter *horizontalBlur;
    __strong GPUImageFilter *verticalBlur;
}

@property (readwrite, nonatomic) CGFloat blurSize;

@end

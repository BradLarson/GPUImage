//
//  GPUImageVignetteFilter.h
//  GPUImage
//
//  Created by Keita Kobayashi on 2/26/12.
//  Copyright (c) 2012 Brad Larson. All rights reserved.
//

#import "GPUImageFilter.h"

@interface GPUImageVignetteFilter : GPUImageFilter {
    GLint xUniform, yUniform;
}

@property (nonatomic, readwrite) CGFloat x;
@property (nonatomic, readwrite) CGFloat y;

@end

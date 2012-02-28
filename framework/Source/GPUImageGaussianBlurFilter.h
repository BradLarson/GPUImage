//
//  GPUImageGaussianBlurFilter.h
//  GPUImage
//
//  Created by Keita Kobayashi on 2/27/12.
//  Copyright (c) 2012 Brad Larson. All rights reserved.
//

#import "GPUImageFilter.h"

@interface GPUImageGaussianBlurFilter : GPUImageFilter {
    GPUImageFilter *horizontalBlur;
    GPUImageFilter *verticalBlur;
}

@property (readwrite, nonatomic) CGFloat blurSize;

@property (readwrite, nonatomic) CGFloat excludeCircleRadius;
@property (readwrite, nonatomic) CGPoint excludeCirclePoint;
@property (readwrite, nonatomic) CGFloat excludeBlurSize;

@end

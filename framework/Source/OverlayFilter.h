//
//  OverlayFilter.h
//  GPUImage
//
//  Created by Shi Yan on 4/27/16.
//  Copyright © 2016 Brad Larson. All rights reserved.
//

#ifndef OverlayFilter_h
#define OverlayFilter_h
#import "GPUImageFilter.h"

@interface OverlayFilter : GPUImageFilter
{
    GLint overlayTextureUniform;
}

@property (readwrite, nonatomic) GLint overlayTexture;

- (id) init;

@end

#endif /* OverlayFilter_h */

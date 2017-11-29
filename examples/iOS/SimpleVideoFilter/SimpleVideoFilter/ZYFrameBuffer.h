//
// Created by zhangyun on 2017/11/28.
// Copyright (c) 2017 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ZYFrameBuffer : NSObject
{
    GLuint  renderTexture;
    CGSize size;
}


- (instancetype)initWithSize:(CGSize)size;
- (void)activeFrameBuffer;

- (GLuint)renderTextureId;
@end
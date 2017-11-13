//
//  ZYGPUImgCtx.m
//  SimpleVideoFilter
//
//  Created by zhangyun on 2017/11/9.
//  Copyright © 2017年 Cell Phone. All rights reserved.
//

#import "ZYGPUImgCtx.h"

@interface ZYGPUImgCtx()
{
    dispatch_queue_t videoProcessingQueue;
}
@property (nonatomic,strong) EAGLContext  *ctx;
@end

@implementation ZYGPUImgCtx

+ (instancetype)shareCtx{
    
    static ZYGPUImgCtx *ctx = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ctx = [[ZYGPUImgCtx alloc] init];
    });
    return ctx;
}

- (dispatch_queue_t)videoProcessingQueue{
    return videoProcessingQueue;
}

- (instancetype)init{
    if (self = [super init]) {
        videoProcessingQueue = dispatch_queue_create("com.nigo.videoprocessingqueue", 0);
    }
    return self;
}
- (EAGLContext *)currentCtx{
    return self.ctx;
}

- (void)userCurrentCtx{
    if (!self.ctx) {
        EAGLContext *ctx = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        self.ctx = ctx;
    }
    [EAGLContext setCurrentContext:self.ctx];
}

@end

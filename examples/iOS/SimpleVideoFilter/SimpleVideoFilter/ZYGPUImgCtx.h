//
//  ZYGPUImgCtx.h
//  SimpleVideoFilter
//
//  Created by zhangyun on 2017/11/9.
//  Copyright © 2017年 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZYGPUImgCtx : NSObject

+ (instancetype)shareCtx;

- (dispatch_queue_t)videoProcessingQueue;


- (void)userCurrentCtx;

- (EAGLContext *)currentCtx;
@end

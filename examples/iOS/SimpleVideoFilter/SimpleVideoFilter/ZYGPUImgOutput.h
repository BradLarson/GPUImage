//
//  ZYGPUImgOutput.h
//  SimpleVideoFilter
//
//  Created by zhangyun on 2017/11/9.
//  Copyright © 2017年 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZYGPUImgInput.h"
#import "ZYGPUImgCtx.h"


void runAsynchronouslyOnVideoProcessQueue(void (^block)(void));

@interface ZYGPUImgOutput : NSObject{
    dispatch_queue_t videoProcessingQueue;
}


- (void)addTarget:(id<ZYGPUImgInput>)target;

@end
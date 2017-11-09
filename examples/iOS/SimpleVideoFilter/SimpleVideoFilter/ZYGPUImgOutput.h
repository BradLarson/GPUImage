//
//  ZYGPUImgOutput.h
//  SimpleVideoFilter
//
//  Created by zhangyun on 2017/11/9.
//  Copyright © 2017年 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZYGPUImgInput.h"



void runAsynchronouslyOnVideoProcessingQueue(void (^block)(void)){
}


@interface ZYGPUImgOutput : NSObject

- (void)addTarget:(id<ZYGPUImgInput>)target;

@end

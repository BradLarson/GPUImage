//
//  ZYGPUImgOutput.m
//  SimpleVideoFilter
//
//  Created by zhangyun on 2017/11/9.
//  Copyright © 2017年 Cell Phone. All rights reserved.
//

#import "ZYGPUImgOutput.h"


void runAsynchronouslyOnVideoProcessQueue(void (^block)(void)){
    if(dispatch_get_current_queue() == [[ZYGPUImgCtx shareCtx] videoProcessingQueue]){
        block();
    }else{
        dispatch_async([[ZYGPUImgCtx shareCtx] videoProcessingQueue], block);
    }
}

@implementation ZYGPUImgOutput


- (instancetype)init {
    if(self = [super init]){

    }
    return self;
}


- (void)addTarget:(id <ZYGPUImgInput>)target {
    if(target){
        [self.targets addObject:target];
    }
}
- (NSMutableArray <ZYGPUImgInput> *)targets {
    if(!_targets){
        _targets = [NSMutableArray array];
    }
    return _targets;
}

@end

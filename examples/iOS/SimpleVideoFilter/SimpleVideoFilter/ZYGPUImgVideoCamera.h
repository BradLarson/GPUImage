//
//  ZYGPUImgVideoCamera.h
//  SimpleVideoFilter
//
//  Created by zhangyun on 2017/11/9.
//  Copyright © 2017年 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZYGPUImgOutput.h"
/**
 采集摄像头数据 传递给下一个。
 */
@interface ZYGPUImgVideoCamera : ZYGPUImgOutput

/**
 start camera capture
 */
- (void)startCapture;
@end

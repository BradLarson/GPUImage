//
//  ZYGPUImgInput.h
//  SimpleVideoFilter
//
//  Created by zhangyun on 2017/11/9.
//  Copyright © 2017年 Cell Phone. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZYGPUImgInput <NSObject>
- (void)newFrame:(id)frame;
@end

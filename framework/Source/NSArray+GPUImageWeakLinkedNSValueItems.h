//
//  NSArray+GPUImageWeakLinkedNSValueItems.h
//  GPUImage
//
//  Created by David Cairns on 9/2/14.
//  Copyright (c) 2014 Brad Larson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (GPUImageWeakLinkedNSValueItems)
- (void)enumerateMixedWeakObjectsUsingBlock:(void (^)(id obj, NSInteger idx, BOOL *stop))block;
@end
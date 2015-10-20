//
//  NSArray+GPUImageWeakLinkedNSValueItems.m
//  GPUImage
//
//  Created by David Cairns on 9/2/14.
//  Copyright (c) 2014 Brad Larson. All rights reserved.
//

#import "NSArray+GPUImageWeakLinkedNSValueItems.h"

@implementation NSArray (GPUImageWeakLinkedNSValueItems)
- (void)enumerateMixedWeakObjectsUsingBlock:(void (^)(id obj, NSInteger idx, BOOL *stop))block;
{
    NSParameterAssert(block);
    
    for(NSInteger idx = 0; idx < self.count; idx++) {
        id objReference = self[idx];
        id actualObject = ([objReference isKindOfClass:[NSValue class]] ? [(NSValue *)objReference nonretainedObjectValue] : objReference);
        NSAssert([actualObject self], @"NSArray probably holding a stale weak (NSValue-wrapped) pointer: %p", actualObject);
        
        BOOL stop = NO;
        block(actualObject, idx, &stop);
        if(stop) {
            return;
        }
    }
}
@end
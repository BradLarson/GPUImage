//
//  NSObject+GPUImageHelpers.m
//  FilterShowcase
//
//  Created by Brent Gulanowski on 2014-05-25.
//  Copyright (c) 2014 Sunset Lake Software LLC. All rights reserved.
//

#import "NSObject+GPUImageHelpers.h"

#import <objc/runtime.h>

@implementation NSObject (GPUImageHelpers)

// From MAObjCRuntime - see http://www.github.com/mikeash/maobjcruntime for license information
// One change - the receiver is NOT in the returned array

+ (NSArray *)gpu_subclasses
{
    Class *buffer = NULL;
    
    int count, size;
    do
    {
        count = objc_getClassList(NULL, 0);
        buffer = realloc(buffer, count * sizeof(*buffer));
        size = objc_getClassList(buffer, count);
    } while(size != count);
    
    NSMutableArray *array = [NSMutableArray array];
    for(int i = 0; i < count; i++)
    {
        Class candidate = buffer[i];
        Class superclass = candidate;
		if (candidate == self) {
			continue;
		}
        while(superclass)
        {
            if(superclass == self)
            {
                [array addObject: candidate];
                break;
            }
            superclass = class_getSuperclass(superclass);
        }
    }
    free(buffer);
    return array;
}

@end

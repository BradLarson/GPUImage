//
//  GPUImageCompletionFilter.m
//  GPUImage
//
//  Created by Emil Palm on 5/9/12.
//  Copyright (c) 2012 Brad Larson. All rights reserved.
//

#import "GPUImageBlocksFilter.h"
@implementation GPUImageBlocksFilter
@synthesize completionBlock = _completionBlock;
@synthesize timingBlock = _timingBlock;

- (void)endProcessing
{
    [super endProcessing];
    if ( self.completionBlock )
        self.completionBlock();
}

- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
{
    [super informTargetsAboutNewFrameAtTime:frameTime];
    
    if ( self.timingBlock )
        self.timingBlock(frameTime);
    
}
@end

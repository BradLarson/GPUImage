//
//  GPUImageCompletionFilter.h
//  GPUImage
//
//  Created by Emil Palm on 5/9/12.
//  Copyright (c) 2012 Brad Larson. All rights reserved.
//

#import "GPUImageFilter.h"
#import "GPUImageBlocks.h"
@interface GPUImageBlocksFilter : GPUImageFilter

// This block will be called in endProccessing.
@property(nonatomic,copy) GPUImageGeneralBlock completionBlock;
@property(nonatomic,copy) GPUImageTimingBlock timingBlock;
@end

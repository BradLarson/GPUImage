//
//  GPUImageSimplexNoiseFilter.h
//  GPUImageMac
//
//  Created by Brent Gulanowski on 2014-05-26.
//  Copyright (c) 2014 Sunset Lake Software LLC. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@interface GPUImageSimplexNoiseFilter : GPUImagePerlinNoiseFilter

@property (nonatomic) CGFloat permuteOffset;
@property (nonatomic) CGFloat permuteScale;

@end

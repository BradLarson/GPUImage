//
//  GPUImageFilter+Showcase.h
//  FilterShowcase
//
//  Created by Brent Gulanowski on 2014-05-24.
//  Copyright (c) 2014 Sunset Lake Software LLC. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@interface GPUImageTransform3DFilter : GPUImageTransformFilter
@end

@interface GPUImageOutput (Showcase)

- (instancetype)initWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view;

- (NSString *)displayName;
- (BOOL)needsSecondImage;
- (NSImage *)secondInputImage;
- (void)setSecondImage:(GPUImagePicture *)image;
- (BOOL)enableSlider;
- (NSString *)sliderKeyPath;
- (CGFloat)minSliderValue;
- (CGFloat)maxSliderValue;

+ (instancetype)showcaseImageOutputWithSource:(GPUImageOutput *)output targetView:(GPUImageView *)view;
+ (NSString *)displayName;
+ (BOOL)excludeFromShowcase;

@end

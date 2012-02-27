//
//  GPUImageGaussianBlurFilter.m
//  GPUImage
//
//  Created by Keita Kobayashi on 2/27/12.
//  Copyright (c) 2012 Brad Larson. All rights reserved.
//

#import "GPUImageGaussianBlurFilter.h"

NSString *const kGPUImageGaussianBlurFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying highp vec2 textureCoordinate;
 
 void main() {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);

NSString *const kGPUImageGaussianBlurHorizontalFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying highp vec2 textureCoordinate;

 uniform highp float blurSize;
 
 uniform lowp float excludeCircleRadius;
 uniform lowp vec2 excludeCirclePoint;
 uniform lowp float excludeBlurSize;
 
 const lowp int samples = 9;
 
 void main()
 {
     mediump float distance = abs(distance(textureCoordinate, excludeCirclePoint));
     highp float ourBlurSize = blurSize;
     if (distance <= excludeCircleRadius) {
         // within the no-blur circle, taper off the blur size until it's 0
         if (distance >= excludeCircleRadius - excludeBlurSize) {
             distance -= excludeCircleRadius - excludeBlurSize;
             ourBlurSize *= distance / excludeBlurSize;
         } else {
             gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
             return;
         }
     }
     
     highp vec4 sum = vec4(0.0);
     
     // blur in x (horizontal)
     // take nine samples, with the distance blurSize between them
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x - 4.0*ourBlurSize, textureCoordinate.y)) * 0.05;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x - 3.0*ourBlurSize, textureCoordinate.y)) * 0.09;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x - 2.0*ourBlurSize, textureCoordinate.y)) * 0.12;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x - ourBlurSize, textureCoordinate.y)) * 0.15;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y)) * 0.18;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x + ourBlurSize, textureCoordinate.y)) * 0.15;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x + 2.0*ourBlurSize, textureCoordinate.y)) * 0.12;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x + 3.0*ourBlurSize, textureCoordinate.y)) * 0.09;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x + 4.0*ourBlurSize, textureCoordinate.y)) * 0.05;
     
     gl_FragColor = sum;
 }
);

NSString *const kGPUImageGaussianBlurVerticalFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying highp vec2 textureCoordinate;
 
 uniform highp float blurSize;
 
 uniform lowp float excludeCircleRadius;
 uniform lowp vec2 excludeCirclePoint;
 uniform lowp float excludeBlurSize;
 
 void main() {
     mediump float distance = abs(distance(textureCoordinate, excludeCirclePoint));
     highp float ourBlurSize = blurSize;
     if (distance <= excludeCircleRadius) {
         // within the no-blur circle, taper off the blur size until it's 0
         if (distance >= excludeCircleRadius - excludeBlurSize) {
             distance -= excludeCircleRadius - excludeBlurSize;
             ourBlurSize *= distance / excludeBlurSize;
         } else {
             gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
             return;
         }
     }
     
     highp vec4 sum = vec4(0.0);
     
     // blur in y (vertical)
     // take nine samples, with the distance blurSize between them
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y - 4.0*ourBlurSize)) * 0.05;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y - 3.0*ourBlurSize)) * 0.09;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y - 2.0*ourBlurSize)) * 0.12;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y - ourBlurSize)) * 0.15;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y)) * 0.18;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y + ourBlurSize)) * 0.15;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y + 2.0*ourBlurSize)) * 0.12;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y + 3.0*ourBlurSize)) * 0.09;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y + 4.0*ourBlurSize)) * 0.05;
     
     gl_FragColor = sum;
 }
);

@implementation GPUImageGaussianBlurFilter

@synthesize blurSize=_blurSize;
@synthesize excludeCirclePoint=_excludeCirclePoint, excludeCircleRadius=_excludeCircleRadius, excludeBlurSize=_excludeBlurSize;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageGaussianBlurFragmentShaderString]))
    {
		return nil;
    }
    
    horizontalBlur = [[GPUImageFilter alloc] initWithFragmentShaderFromString:kGPUImageGaussianBlurHorizontalFragmentShaderString];
    verticalBlur = [[GPUImageFilter alloc] initWithFragmentShaderFromString:kGPUImageGaussianBlurVerticalFragmentShaderString];
    
    [self addTarget:horizontalBlur];
    [horizontalBlur addTarget:verticalBlur];
    for (NSObject<GPUImageInput>* target in targets) {
        if ([target isEqual:horizontalBlur]) continue;
        [verticalBlur addTarget:target];
    }
    
    self.blurSize = 1.0/320.0;
    
    self.excludeCircleRadius = 60.0/320.0;
    self.excludeCirclePoint = CGPointMake(0.5, 0.5);
    self.excludeBlurSize = 10.0/320.0;
    
    return self;
}

- (void) addTarget:(NSObject<GPUImageInput>*)newTarget {
    if ([newTarget isEqual:horizontalBlur]) [super addTarget:newTarget];
    else [verticalBlur addTarget:newTarget];
}

- (void) removeAllTargets {
    [verticalBlur removeAllTargets];
}

- (void) removeTarget:(id<GPUImageInput>)targetToRemove {
    [verticalBlur removeTarget:targetToRemove];
}

- (UIImage *)imageFromCurrentlyProcessedOutput {
    return [verticalBlur imageFromCurrentlyProcessedOutput];
}

- (UIImage *)imageByFilteringImage:(UIImage *)imageToFilter {
    UIImage *intermediaryImage = [horizontalBlur imageByFilteringImage:imageToFilter];
    return [verticalBlur imageByFilteringImage:intermediaryImage];
}

#pragma mark Getters and Setters

- (void) setBlurSize:(CGFloat)blurSize {
    _blurSize = blurSize;

    [horizontalBlur setFloat:_blurSize forUniform:@"blurSize"];
    [verticalBlur setFloat:_blurSize forUniform:@"blurSize"];
}

- (void) setExcludeCirclePoint:(CGPoint)excludeCirclePoint {
    _excludeCirclePoint = excludeCirclePoint;
    
    [horizontalBlur setPoint:_excludeCirclePoint forUniform:@"excludeCirclePoint"];
    [verticalBlur setPoint:_excludeCirclePoint forUniform:@"excludeCirclePoint"];
}

- (void) setExcludeCircleRadius:(CGFloat)excludeCircleRadius {
    _excludeCircleRadius = excludeCircleRadius;
    
    [horizontalBlur setFloat:_excludeCircleRadius forUniform:@"excludeCircleRadius"];
    [verticalBlur setFloat:_excludeCircleRadius forUniform:@"excludeCircleRadius"];
}

- (void) setExcludeBlurSize:(CGFloat)excludeBlurSize {
    _excludeBlurSize = excludeBlurSize;
    
    [horizontalBlur setFloat:_excludeBlurSize forUniform:@"excludeBlurSize"];
    [verticalBlur setFloat:_excludeBlurSize forUniform:@"excludeBlurSize"];
}

@end

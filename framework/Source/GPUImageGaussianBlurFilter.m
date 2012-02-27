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
 uniform lowp int sampleCount;
 
 void main()
 {
     highp vec4 sum = vec4(0.0);
     
     // blur in x (horizontal)
     // take nine samples, with the distance blurSize between them
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x - 4.0*blurSize, textureCoordinate.y)) * 0.05;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x - 3.0*blurSize, textureCoordinate.y)) * 0.09;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x - 2.0*blurSize, textureCoordinate.y)) * 0.12;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x - blurSize, textureCoordinate.y)) * 0.15;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y)) * 0.16;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x + blurSize, textureCoordinate.y)) * 0.15;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x + 2.0*blurSize, textureCoordinate.y)) * 0.12;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x + 3.0*blurSize, textureCoordinate.y)) * 0.09;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x + 4.0*blurSize, textureCoordinate.y)) * 0.05;
     
     
     gl_FragColor = sum;
 }
);

NSString *const kGPUImageGaussianBlurVerticalFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying highp vec2 textureCoordinate;
 
 uniform highp float blurSize;
 
 void main() {
     highp vec4 sum = vec4(0.0);
     
     // blur in y (vertical)
     // take nine samples, with the distance blurSize between them
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y - 4.0*blurSize)) * 0.05;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y - 3.0*blurSize)) * 0.09;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y - 2.0*blurSize)) * 0.12;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y - blurSize)) * 0.15;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y)) * 0.16;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y + blurSize)) * 0.15;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y + 2.0*blurSize)) * 0.12;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y + 3.0*blurSize)) * 0.09;
     sum += texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y + 4.0*blurSize)) * 0.05;
     
     gl_FragColor = sum;
 }
);

@implementation GPUImageGaussianBlurFilter

@synthesize blurSize=_blurSize;

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

- (void) setBlurSize:(CGFloat)blurSize {
    _blurSize = blurSize;

    [horizontalBlur setFloat:_blurSize forUniform:@"blurSize"];
    [verticalBlur setFloat:_blurSize forUniform:@"blurSize"];
}

@end

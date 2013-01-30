//
//  GPUImageTwoInput3x3TextureSamplingFilter.m
//  GPUImage
//
//  Created by Ian Simon on 1/29/13.
//  Copyright (c) 2013 Brad Larson. All rights reserved.
//

#import "GPUImageTwoInput3x3TextureSamplingFilter.h"

NSString *const kGPUImageTwoInputNearbyTexelSamplingVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 attribute vec4 inputTextureCoordinate2;
 
 uniform highp float texelWidth;
 uniform highp float texelHeight;
 
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 varying vec2 textureCoordinate2;
 varying vec2 leftTextureCoordinate2;
 varying vec2 rightTextureCoordinate2;
 
 varying vec2 topTextureCoordinate2;
 varying vec2 topLeftTextureCoordinate2;
 varying vec2 topRightTextureCoordinate2;
 
 varying vec2 bottomTextureCoordinate2;
 varying vec2 bottomLeftTextureCoordinate2;
 varying vec2 bottomRightTextureCoordinate2;
 
 void main()
 {
     gl_Position = position;
     
     vec2 widthStep = vec2(texelWidth, 0.0);
     vec2 heightStep = vec2(0.0, texelHeight);
     vec2 widthHeightStep = vec2(texelWidth, texelHeight);
     vec2 widthNegativeHeightStep = vec2(texelWidth, -texelHeight);
     
     textureCoordinate = inputTextureCoordinate.xy;
     leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
     rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;
     
     topTextureCoordinate = inputTextureCoordinate.xy - heightStep;
     topLeftTextureCoordinate = inputTextureCoordinate.xy - widthHeightStep;
     topRightTextureCoordinate = inputTextureCoordinate.xy + widthNegativeHeightStep;
     
     bottomTextureCoordinate = inputTextureCoordinate.xy + heightStep;
     bottomLeftTextureCoordinate = inputTextureCoordinate.xy - widthNegativeHeightStep;
     bottomRightTextureCoordinate = inputTextureCoordinate.xy + widthHeightStep;
     
     textureCoordinate2 = inputTextureCoordinate2.xy;
     leftTextureCoordinate2 = inputTextureCoordinate2.xy - widthStep;
     rightTextureCoordinate2 = inputTextureCoordinate2.xy + widthStep;
     
     topTextureCoordinate2 = inputTextureCoordinate2.xy - heightStep;
     topLeftTextureCoordinate2 = inputTextureCoordinate2.xy - widthHeightStep;
     topRightTextureCoordinate2 = inputTextureCoordinate2.xy + widthNegativeHeightStep;
     
     bottomTextureCoordinate2 = inputTextureCoordinate2.xy + heightStep;
     bottomLeftTextureCoordinate2 = inputTextureCoordinate2.xy - widthNegativeHeightStep;
     bottomRightTextureCoordinate2 = inputTextureCoordinate2.xy + widthHeightStep;
 }
);

@implementation GPUImageTwoInput3x3TextureSamplingFilter

@synthesize texelWidth = _texelWidth;
@synthesize texelHeight = _texelHeight;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageTwoInputNearbyTexelSamplingVertexShaderString fragmentShaderFromString:fragmentShaderString]))
    {
        return nil;
    }
    
    texelWidthUniform = [filterProgram uniformIndex:@"texelWidth"];
    texelHeightUniform = [filterProgram uniformIndex:@"texelHeight"];
    
    return self;
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    if (!hasOverriddenImageSizeFactor)
    {
        _texelWidth = 1.0 / filterFrameSize.width;
        _texelHeight = 1.0 / filterFrameSize.height;
        
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
            if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
            {
                glUniform1f(texelWidthUniform, _texelHeight);
                glUniform1f(texelHeightUniform, _texelWidth);
            }
            else
            {
                glUniform1f(texelWidthUniform, _texelWidth);
                glUniform1f(texelHeightUniform, _texelHeight);
            }
        });
    }
}

#pragma mark -
#pragma mark Accessors

- (void)setTexelWidth:(CGFloat)newValue;
{
    hasOverriddenImageSizeFactor = YES;
    _texelWidth = newValue;
    
    [self setFloat:_texelWidth forUniform:texelWidthUniform program:filterProgram];
}

- (void)setTexelHeight:(CGFloat)newValue;
{
    hasOverriddenImageSizeFactor = YES;
    _texelHeight = newValue;
    
    [self setFloat:_texelHeight forUniform:texelHeightUniform program:filterProgram];
}

@end

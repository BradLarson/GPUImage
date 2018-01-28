
//
//  GPUImageSmartEyeSkinDetectSmoothCSEnhanceBetter.m
//  XiaoKa
//
//  Created by ShawnDu on 15/11/7.
//  Copyright © 2015年 SmarterEye. All rights reserved.
//

#import "GPUImageSmartEyeSkinDetectSmoothCSEnhanceBetter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageSmartEyeSkinDetectSmoothCSEnhanceBetterFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform mediump int mLevel;
 uniform mediump int sLevel;
 uniform mediump float mXStep;
 uniform mediump float mYStep;
 uniform mediump float contrastRatio_10bit;
 uniform mediump float saturationRatio_10bit;
 uniform mediump int contrastKeyPoint;
 
 void main()
 {
     
     mediump vec4 base = texture2D(inputImageTexture, textureCoordinate);
     
     //Smooth
     mediump float distanceNormalizationFactor =4.0;
     mediump int count = 0;
     mediump float step = 16.0;
     lowp vec4 centralColor;
     lowp float gaussianWeightTotal;
     lowp vec4 sum;
     lowp vec4 sampleColor;
     lowp float distanceFromCentralColor;
     lowp float gaussianWeight;
     centralColor = base;
     gaussianWeightTotal = 0.4;
     sum = centralColor * 0.4;
     mediump float test = 0.3;
     
     mediump vec2 singleStepOffset = vec2(textureCoordinate.x -step*mXStep, textureCoordinate.y -step*mYStep);
     sampleColor = texture2D(inputImageTexture, singleStepOffset);
     
     if((sampleColor.x < test)&&(centralColor.x < test))
     {
         count += 1;
         gaussianWeightTotal += 0.045;
         sum += centralColor * 0.045;
     }else{
         distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
         gaussianWeight = 0.045 * (1.0 - distanceFromCentralColor);
         gaussianWeightTotal += gaussianWeight;
         sum += sampleColor * gaussianWeight;
     }
     
     singleStepOffset = vec2(textureCoordinate.x , textureCoordinate.y -step*mYStep);
     sampleColor = texture2D(inputImageTexture, singleStepOffset);
     
     if((sampleColor.x < test)&&(centralColor.x < test))
     {
         count += 1;
         gaussianWeightTotal += 0.045;
         sum += centralColor * 0.045;
     }else{
         distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
         gaussianWeight = 0.045 * (1.0 - distanceFromCentralColor);
         gaussianWeightTotal += gaussianWeight;
         sum += sampleColor * gaussianWeight;
     }
     
     singleStepOffset = vec2(textureCoordinate.x +step*mXStep, textureCoordinate.y -step*mYStep);
     sampleColor = texture2D(inputImageTexture, singleStepOffset);
     
     if((sampleColor.x < test)&&(centralColor.x < test))
     {
         count += 1;
         gaussianWeightTotal += 0.045;
         sum += centralColor * 0.045;
     }else{
         distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
         gaussianWeight = 0.045 * (1.0 - distanceFromCentralColor);
         gaussianWeightTotal += gaussianWeight;
         sum += sampleColor * gaussianWeight;
     }
     
     singleStepOffset = vec2(textureCoordinate.x -step*mXStep, textureCoordinate.y);
     sampleColor = texture2D(inputImageTexture, singleStepOffset);
     
     if((sampleColor.x < test)&&(centralColor.x < test))
     {
         count += 1;
         gaussianWeightTotal += 0.045;
         sum += centralColor * 0.045;
     }else{
         distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
         gaussianWeight = 0.045 * (1.0 - distanceFromCentralColor);
         gaussianWeightTotal += gaussianWeight;
         sum += sampleColor * gaussianWeight;
     }
     
     singleStepOffset = vec2(textureCoordinate.x +step*mXStep, textureCoordinate.y);
     sampleColor = texture2D(inputImageTexture, singleStepOffset);
     
     if((sampleColor.x < test)&&(centralColor.x < test))
     {
         count += 1;
         gaussianWeightTotal += 0.045;
         sum += centralColor * 0.045;
     }else{
         distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
         gaussianWeight = 0.045 * (1.0 - distanceFromCentralColor);
         gaussianWeightTotal += gaussianWeight;
         sum += sampleColor * gaussianWeight;
     }
     
     singleStepOffset = vec2(textureCoordinate.x -step*mXStep, textureCoordinate.y +step*mYStep);
     sampleColor = texture2D(inputImageTexture, singleStepOffset);
     
     if((sampleColor.x < test)&&(centralColor.x < test))
     {
         count += 1;
         gaussianWeightTotal += 0.045;
         sum += centralColor * 0.045;
     }else{
         distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
         gaussianWeight = 0.045 * (1.0 - distanceFromCentralColor);
         gaussianWeightTotal += gaussianWeight;
         sum += sampleColor * gaussianWeight;
     }
     
     singleStepOffset = vec2(textureCoordinate.x , textureCoordinate.y +step*mYStep);
     sampleColor = texture2D(inputImageTexture, singleStepOffset);
     
     if((sampleColor.x < test)&&(centralColor.x < test))
     {
         count += 1;
         gaussianWeightTotal += 0.045;
         sum += centralColor * 0.045;
     }else{
         distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
         gaussianWeight = 0.045 * (1.0 - distanceFromCentralColor);
         gaussianWeightTotal += gaussianWeight;
         sum += sampleColor * gaussianWeight;
     }
     
     singleStepOffset = vec2(textureCoordinate.x + step*mXStep, textureCoordinate.y +step*mYStep);
     sampleColor = texture2D(inputImageTexture, singleStepOffset);
     
     if((sampleColor.x < test)&&(centralColor.x < test))
     {
         count += 1;
         gaussianWeightTotal += 0.045;
         sum += centralColor * 0.045;
     }else{
         distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
         gaussianWeight = 0.045 * (1.0 - distanceFromCentralColor);
         gaussianWeightTotal += gaussianWeight;
         sum += sampleColor * gaussianWeight;
     }
     
     singleStepOffset = vec2(textureCoordinate.x , textureCoordinate.y - 0.5*step*mYStep);
     sampleColor = texture2D(inputImageTexture, singleStepOffset);
     
     if((sampleColor.x < test)&&(centralColor.x < test))
     {
         count += 1;
         gaussianWeightTotal += 0.06;
         sum += centralColor * 0.06;
     }else{
         distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
         gaussianWeight = 0.06 * (1.0 - distanceFromCentralColor);
         gaussianWeightTotal += gaussianWeight;
         sum += sampleColor * gaussianWeight;
     }
     
     singleStepOffset = vec2(textureCoordinate.x -0.5*step*mXStep, textureCoordinate.y);
     sampleColor = texture2D(inputImageTexture, singleStepOffset);
     
     
     if((sampleColor.x < test)&&(centralColor.x < test))
     {
         count += 1;
         gaussianWeightTotal += 0.06;
         sum += centralColor * 0.06;
     }else{
         distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
         gaussianWeight = 0.06 * (1.0 - distanceFromCentralColor);
         gaussianWeightTotal += gaussianWeight;
         sum += sampleColor * gaussianWeight;
     }
     
     singleStepOffset = vec2(textureCoordinate.x +0.5*step*mXStep, textureCoordinate.y);
     sampleColor = texture2D(inputImageTexture, singleStepOffset);
     
     
     if((sampleColor.x < test)&&(centralColor.x < test))
     {
         count += 1;
         gaussianWeightTotal += 0.06;
         sum += centralColor * 0.06;
     }else{
         distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
         gaussianWeight = 0.06 * (1.0 - distanceFromCentralColor);
         gaussianWeightTotal += gaussianWeight;
         sum += sampleColor * gaussianWeight;
     }
     
     singleStepOffset = vec2(textureCoordinate.x , textureCoordinate.y + 0.5*step*mYStep);
     sampleColor = texture2D(inputImageTexture, singleStepOffset);
     
     
     if((sampleColor.x < test)&&(centralColor.x < test))
     {
         count += 1;
         gaussianWeightTotal += 0.06;
         sum += centralColor * 0.06;
     }else{
         distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
         gaussianWeight = 0.06 * (1.0 - distanceFromCentralColor);
         gaussianWeightTotal += gaussianWeight;
         sum += sampleColor * gaussianWeight;
     }

     if(count < 4)
     {
         base = sum / gaussianWeightTotal;
     }
     
     mediump float curR = base.r;
     mediump float curG = base.g;
     mediump float curB = base.b;
     curR *= 255.0;
     curG *= 255.0;
     curB *= 255.0;
     
     mediump float curY = 0.257*curR + 0.504*curG + 0.098*curB+16.0;
     mediump float curU = -0.148*curR - 0.291*curG + 0.439*curB+128.0;
     mediump float curV = 0.439*curR - 0.368*curG - 0.071*curB+128.0;
     curY = min(max(curY, 0.0), 255.0);
     curU = min(max(curU, 0.0), 255.0);
     curV = min(max(curV, 0.0), 255.0);
     
     //CSEhance\n" +
     mediump float tempY;
     mediump float tempU;
     mediump float tempV;
     tempU = curU - 128.0;
     tempV = curV - 128.0;
     tempY = curY - float(contrastKeyPoint);
     
     abs(tempU);
     tempU = tempU*saturationRatio_10bit + 0.5;
     
     abs(tempV);
     tempV = tempV*saturationRatio_10bit + 0.5;
     
     abs(tempY);
     tempY = tempY*contrastRatio_10bit + 0.5;
     
     curY = tempY + float(contrastKeyPoint);
     curU = tempU + 128.0;
     curV = tempV + 128.0;
     
     curR = 1.164*(curY -16.0) + 1.5958*(curV-128.0);
     curG = 1.164*(curY-16.0) - 0.81290*(curV-128.0) - 0.39173*(curU-128.0);
     curB = 1.164*(curY-16.0) + 2.017*(curU-128.0);
     
     curR /= 255.0;
     curG /= 255.0;
     curB /= 255.0;
     curR = min(max(curR, 0.0), 1.0);
     curG = min(max(curG, 0.0), 1.0);
     curB = min(max(curB, 0.0), 1.0);
     gl_FragColor = vec4(curR, curG, curB, 1.0);
 }
 );
#else
#endif

@implementation GPUImageSmartEyeSkinDetectSmoothCSEnhanceBetter

@synthesize mLevel = _mLevel;
@synthesize mXStep = _mXStep;
@synthesize mYStep = _mYStep;
@synthesize sLevel = _sLevel;
@synthesize contrastRatio_10bit = _contrastRatio_10bit;
@synthesize contrastKeyPoint = _contrastKeyPoint;
@synthesize saturationRatio_10bit = _saturationRatio_10bit;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSmartEyeSkinDetectSmoothCSEnhanceBetterFragmentShaderString]))
    {
        return nil;
    }
    
    mLevelUniform = [filterProgram uniformIndex:@"mLevel"];
    mXStepUniform = [filterProgram uniformIndex:@"mXStep"];
    mYStepUniform = [filterProgram uniformIndex:@"mYStep"];
    sLevelUniform = [filterProgram uniformIndex:@"sLevel"];
    contrastRatio_10bitUniform = [filterProgram uniformIndex:@"contrastRatio_10bit"];
    contrastKeyPointUniform = [filterProgram uniformIndex:@"contrastKeyPoint"];
    saturationRatio_10bitUniform = [filterProgram uniformIndex:@"saturationRatio_10bit"];
    
    self.mLevel = 50;
    self.sLevel = 50;
    self.contrastRatio_10bit = 1.1;
    self.contrastKeyPoint = 64.0;
    self.saturationRatio_10bit = 1.2;
    
    return self;
}

#pragma mark -
#pragma mark Initialization and teardown

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    _mXStep = 1.0 / filterFrameSize.width;
    _mYStep = 1.0 / filterFrameSize.height;
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:filterProgram];
        if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
        {
            glUniform1f(mXStepUniform, _mXStep);
            glUniform1f(mYStepUniform, _mYStep);
        }
        else
        {
            glUniform1f(mXStepUniform, _mXStep);
            glUniform1f(mYStepUniform, _mYStep);
        }
    });
}

#pragma mark -
#pragma mark Accessors

- (void)setMLevel:(CGFloat)mlevel;
{
    _mLevel = mlevel;
    
    [self setInteger:_mLevel forUniform:mLevelUniform program:filterProgram];
}

- (void)setMXStep:(CGFloat)newValue;
{
    _mXStep = newValue;
    
    [self setFloat:_mXStep forUniform:mXStepUniform program:filterProgram];
}

- (void)setMYStep:(CGFloat)newValue;
{
    _mYStep = newValue;
    
    [self setFloat:_mYStep forUniform:mYStepUniform program:filterProgram];
}

- (void)setSLevel:(CGFloat)newValue;
{
    _sLevel = newValue;
    
    [self setInteger:_sLevel forUniform:sLevelUniform program:filterProgram];
}

- (void)setContrastRatio_10bit:(CGFloat)cLevel;
{
    _contrastRatio_10bit = cLevel;
    _contrastKeyPoint = 64;
    _saturationRatio_10bit = 1.2;
    
    [self setFloat:_contrastRatio_10bit forUniform:contrastRatio_10bitUniform program:filterProgram];
    [self setInteger:_contrastKeyPoint forUniform:contrastKeyPointUniform program:filterProgram];
    [self setFloat:_saturationRatio_10bit forUniform:saturationRatio_10bitUniform program:filterProgram];
}

@end


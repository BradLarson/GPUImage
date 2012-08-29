#import "GPUImageBoxBlurFilter.h"

NSString *const kGPUImageBoxBlurVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;

 uniform float texelWidthOffset; 
 uniform float texelHeightOffset; 
 uniform highp float blurSize;

 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepLeftTextureCoordinate;
 varying vec2 twoStepsLeftTextureCoordinate;
 varying vec2 oneStepRightTextureCoordinate;
 varying vec2 twoStepsRightTextureCoordinate;

 void main()
 {
     gl_Position = position;
          
     vec2 firstOffset = vec2(1.5 * texelWidthOffset, 1.5 * texelHeightOffset) * blurSize;
     vec2 secondOffset = vec2(3.5 * texelWidthOffset, 3.5 * texelHeightOffset) * blurSize;
     
     centerTextureCoordinate = inputTextureCoordinate;
     oneStepLeftTextureCoordinate = inputTextureCoordinate - firstOffset;
     twoStepsLeftTextureCoordinate = inputTextureCoordinate - secondOffset;
     oneStepRightTextureCoordinate = inputTextureCoordinate + firstOffset;
     twoStepsRightTextureCoordinate = inputTextureCoordinate + secondOffset;
 }
);


NSString *const kGPUImageBoxBlurFragmentShaderString = SHADER_STRING
(
 precision highp float;

 uniform sampler2D inputImageTexture;
 
 varying vec2 centerTextureCoordinate;
 varying vec2 oneStepLeftTextureCoordinate;
 varying vec2 twoStepsLeftTextureCoordinate;
 varying vec2 oneStepRightTextureCoordinate;
 varying vec2 twoStepsRightTextureCoordinate;
 
 void main()
 {
     lowp vec4 fragmentColor = texture2D(inputImageTexture, centerTextureCoordinate) * 0.2;
     fragmentColor += texture2D(inputImageTexture, oneStepLeftTextureCoordinate) * 0.2;
     fragmentColor += texture2D(inputImageTexture, oneStepRightTextureCoordinate) * 0.2;
     fragmentColor += texture2D(inputImageTexture, twoStepsLeftTextureCoordinate) * 0.2;
     fragmentColor += texture2D(inputImageTexture, twoStepsRightTextureCoordinate) * 0.2;
     
     gl_FragColor = fragmentColor;
 }
);

@implementation GPUImageBoxBlurFilter

@synthesize blurSize = _blurSize;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFirstStageVertexShaderFromString:kGPUImageBoxBlurVertexShaderString firstStageFragmentShaderFromString:kGPUImageBoxBlurFragmentShaderString secondStageVertexShaderFromString:kGPUImageBoxBlurVertexShaderString secondStageFragmentShaderFromString:kGPUImageBoxBlurFragmentShaderString]))
    {
		return nil;
    }
    
    firstBlurSizeUniform = [filterProgram uniformIndex:@"blurSize"];
    secondBlurSizeUniform = [secondFilterProgram uniformIndex:@"blurSize"];

    self.blurSize = 1.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setBlurSize:(CGFloat)newValue;
{
    _blurSize = newValue;
    
    [self setFloat:_blurSize forUniform:firstBlurSizeUniform program:filterProgram];
    [self setFloat:_blurSize forUniform:secondBlurSizeUniform program:secondFilterProgram];
}

@end


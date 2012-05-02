#import "GPUImage3x3ConvolutionFilter.h"

// Override vertex shader to remove dependent texture reads 
NSString *const kGPUImageNearbyTexelSamplingVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform highp float imageWidthFactor; 
 uniform highp float imageHeightFactor; 
 
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 void main()
 {
     gl_Position = position;
     
     vec2 widthStep = vec2(imageWidthFactor, 0.0);
     vec2 heightStep = vec2(0.0, imageHeightFactor);
     vec2 widthHeightStep = vec2(imageWidthFactor, imageHeightFactor);
     vec2 widthNegativeHeightStep = vec2(imageWidthFactor, -imageHeightFactor);
     
     textureCoordinate = inputTextureCoordinate.xy;
     leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
     rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;
     
     topTextureCoordinate = inputTextureCoordinate.xy - heightStep;
     topLeftTextureCoordinate = inputTextureCoordinate.xy - widthHeightStep;
     topRightTextureCoordinate = inputTextureCoordinate.xy + widthNegativeHeightStep;
     
     bottomTextureCoordinate = inputTextureCoordinate.xy + heightStep;
     bottomLeftTextureCoordinate = inputTextureCoordinate.xy - widthNegativeHeightStep;
     bottomRightTextureCoordinate = inputTextureCoordinate.xy + widthHeightStep;
 }
);


NSString *const kGPUImage3x3ConvolutionFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform mediump mat3 convolutionMatrix;
 
 void main()
 {
     mediump vec4 bottomColor = texture2D(inputImageTexture, bottomTextureCoordinate);
     mediump vec4 bottomLeftColor = texture2D(inputImageTexture, bottomLeftTextureCoordinate);
     mediump vec4 bottomRightColor = texture2D(inputImageTexture, bottomRightTextureCoordinate);
     mediump vec4 centerColor = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 leftColor = texture2D(inputImageTexture, leftTextureCoordinate);
     mediump vec4 rightColor = texture2D(inputImageTexture, rightTextureCoordinate);
     mediump vec4 topColor = texture2D(inputImageTexture, topTextureCoordinate);
     mediump vec4 topRightColor = texture2D(inputImageTexture, topRightTextureCoordinate);
     mediump vec4 topLeftColor = texture2D(inputImageTexture, topLeftTextureCoordinate);

     mediump vec4 resultColor = topLeftColor * convolutionMatrix[0][0] + topColor * convolutionMatrix[0][1] + topRightColor * convolutionMatrix[0][2];
     resultColor += leftColor * convolutionMatrix[1][0] + centerColor * convolutionMatrix[1][1] + rightColor * convolutionMatrix[1][2];
     resultColor += bottomLeftColor * convolutionMatrix[2][0] + bottomColor * convolutionMatrix[2][1] + bottomRightColor * convolutionMatrix[2][2];

     gl_FragColor = resultColor;
 }
);                                                                         

@implementation GPUImage3x3ConvolutionFilter

@synthesize convolutionKernel = _convolutionKernel;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageNearbyTexelSamplingVertexShaderString fragmentShaderFromString:kGPUImage3x3ConvolutionFragmentShaderString]))
    {
        return nil;
    }
    
    convolutionMatrixUniform = [filterProgram uniformIndex:@"convolutionMatrix"];
    imageWidthFactorUniform = [filterProgram uniformIndex:@"imageWidthFactor"];
    imageHeightFactorUniform = [filterProgram uniformIndex:@"imageHeightFactor"];

    self.convolutionKernel = (GPUMatrix3x3){
        {0.f, 0.f, 0.f},
        {0.f, 1.f, 0.f},
        {0.f, 0.f, 0.f}
    };
    
    return self;
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    imageWidthFactor = filterFrameSize.width;
    imageHeightFactor = filterFrameSize.height;
        
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(imageWidthFactorUniform, 1.0 / imageWidthFactor);
    glUniform1f(imageHeightFactorUniform, 1.0 / imageHeightFactor);
}

#pragma mark -
#pragma mark Accessors

- (void)setConvolutionKernel:(GPUMatrix3x3)newValue;
{
    _convolutionKernel = newValue;
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    
    glUniformMatrix3fv(convolutionMatrixUniform, 1, GL_FALSE, (GLfloat *)&_convolutionKernel);
}

@end

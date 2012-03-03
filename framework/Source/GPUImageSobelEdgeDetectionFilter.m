#import "GPUImageSobelEdgeDetectionFilter.h"

// Override vertex shader to remove dependent texture reads 
NSString *const kGPUImageSobelEdgeDetectionVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;

 uniform mediump float imageWidthFactor; 
 uniform mediump float imageHeightFactor; 

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
     
     mediump vec2 widthStep = vec2(imageWidthFactor, 0.0);
     mediump vec2 heightStep = vec2(0.0, imageHeightFactor);
     mediump vec2 widthHeightStep = vec2(imageWidthFactor, imageHeightFactor);
     mediump vec2 widthNegativeHeightStep = vec2(imageWidthFactor, -imageHeightFactor);

     textureCoordinate = inputTextureCoordinate.xy;
     leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
     rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;

     topTextureCoordinate = inputTextureCoordinate.xy + heightStep;
     topLeftTextureCoordinate = inputTextureCoordinate.xy - widthNegativeHeightStep;
     topRightTextureCoordinate = inputTextureCoordinate.xy + widthHeightStep;

     bottomTextureCoordinate = inputTextureCoordinate.xy - heightStep;
     bottomLeftTextureCoordinate = inputTextureCoordinate.xy - widthHeightStep;
     bottomRightTextureCoordinate = inputTextureCoordinate.xy + widthNegativeHeightStep;
}
);

//   Code from "Graphics Shaders: Theory and Practice" by M. Bailey and S. Cunningham 
NSString *const kGPUImageSobelEdgeDetectionFragmentShaderString = SHADER_STRING
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
 
 const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
    vec3 textureColor = texture2D(inputImageTexture, textureCoordinate).rgb;
        
    float i00   = textureColor.r;
    float im1m1 = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float ip1p1 = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float im1p1 = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float ip1m1 = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float im10 = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float ip10 = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float i0m1 = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float i0p1 = texture2D(inputImageTexture, topTextureCoordinate).r;
    float h = -im1p1 - 2.0 * i0p1 - ip1p1 + im1m1 + 2.0 * i0m1 + ip1m1;
    float v = -im1m1 - 2.0 * im10 - im1p1 + ip1m1 + 2.0 * ip10 + ip1p1;
    
    float mag = length(vec2(h, v));
    
    gl_FragColor = vec4(vec3(mag), 1.0);
 }
);

//float i00   = dot( textureColor, W);
//float im1m1 = dot( texture2D(inputImageTexture, bottomLeftTextureCoordinate).rgb, W);
//float ip1p1 = dot( texture2D(inputImageTexture, topRightTextureCoordinate).rgb, W);
//float im1p1 = dot( texture2D(inputImageTexture, topLeftTextureCoordinate).rgb, W);
//float ip1m1 = dot( texture2D(inputImageTexture, bottomRightTextureCoordinate).rgb, W);
//float im10 = dot( texture2D(inputImageTexture, leftTextureCoordinate).rgb, W);
//float ip10 = dot( texture2D(inputImageTexture, rightTextureCoordinate).rgb, W);
//float i0m1 = dot( texture2D(inputImageTexture, bottomTextureCoordinate).rgb, W);
//float i0p1 = dot( texture2D(inputImageTexture, topTextureCoordinate).rgb, W);
//float h = -im1p1 - 2.0 * i0p1 - ip1p1 + im1m1 + 2.0 * i0m1 + ip1m1;
//float v = -im1m1 - 2.0 * im10 - im1p1 + ip1m1 + 2.0 * ip10 + ip1p1;


@implementation GPUImageSobelEdgeDetectionFilter

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageSobelEdgeDetectionVertexShaderString fragmentShaderFromString:fragmentShaderString]))
    {
		return nil;
    }
    
    hasOverriddenImageSizeFactor = NO;
    
    imageWidthFactorUniform = [filterProgram uniformIndex:@"imageWidthFactor"];
    imageHeightFactorUniform = [filterProgram uniformIndex:@"imageHeightFactor"];
    
    return self;
}

- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kGPUImageSobelEdgeDetectionFragmentShaderString]))
    {
		return nil;
    }

    return self;
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    if (!hasOverriddenImageSizeFactor)
    {
        _imageWidthFactor = filterFrameSize.width;
        _imageHeightFactor = filterFrameSize.height;

        [GPUImageOpenGLESContext useImageProcessingContext];
        [filterProgram use];
        glUniform1f(imageWidthFactorUniform, 1.0 / _imageWidthFactor);
        glUniform1f(imageHeightFactorUniform, 1.0 / _imageHeightFactor);
    }
}

#pragma mark -
#pragma mark Accessors

@synthesize imageWidthFactor = _imageWidthFactor; 
@synthesize imageHeightFactor = _imageHeightFactor; 

- (void)setImageWidthFactor:(CGFloat)newValue;
{
    hasOverriddenImageSizeFactor = YES;
    _imageWidthFactor = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(imageWidthFactorUniform, 1.0 / _imageWidthFactor);
}

- (void)setImageHeightFactor:(CGFloat)newValue;
{
    hasOverriddenImageSizeFactor = YES;
    _imageHeightFactor = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(imageHeightFactorUniform, 1.0 / _imageHeightFactor);
}

@end


#import "GPUImageSobelEdgeDetectionFilter.h"
#import "GPUImageGrayscaleFilter.h"

// Override vertex shader to remove dependent texture reads 
NSString *const kGPUImageSobelEdgeDetectionVertexShaderString = SHADER_STRING
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
 
 void main()
 {
    float i00   = texture2D(inputImageTexture, textureCoordinate).r;
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

@implementation GPUImageSobelEdgeDetectionFilter

@synthesize imageWidthFactor = _imageWidthFactor; 
@synthesize imageHeightFactor = _imageHeightFactor; 

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kGPUImageSobelEdgeDetectionFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}


- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
{
    // Do a luminance pass first to reduce the calculations performed at each fragment in the edge detection phase

    if (!(self = [super initWithFirstStageVertexShaderFromString:kGPUImageVertexShaderString firstStageFragmentShaderFromString:kGPUImageLuminanceFragmentShaderString secondStageVertexShaderFromString:kGPUImageSobelEdgeDetectionVertexShaderString secondStageFragmentShaderFromString:fragmentShaderString]))
    {
		return nil;
    }
    
    hasOverriddenImageSizeFactor = NO;
    
    imageWidthFactorUniform = [secondFilterProgram uniformIndex:@"imageWidthFactor"];
    imageHeightFactorUniform = [secondFilterProgram uniformIndex:@"imageHeightFactor"];
    
    return self;
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    if (!hasOverriddenImageSizeFactor)
    {
        _imageWidthFactor = filterFrameSize.width;
        _imageHeightFactor = filterFrameSize.height;

        [GPUImageOpenGLESContext useImageProcessingContext];
        [secondFilterProgram use];
        glUniform1f(imageWidthFactorUniform, 1.0 / _imageWidthFactor);
        glUniform1f(imageHeightFactorUniform, 1.0 / _imageHeightFactor);
    }
}

#pragma mark -
#pragma mark Accessors

- (void)setImageWidthFactor:(CGFloat)newValue;
{
    hasOverriddenImageSizeFactor = YES;
    _imageWidthFactor = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [secondFilterProgram use];
    glUniform1f(imageWidthFactorUniform, 1.0 / _imageWidthFactor);
}

- (void)setImageHeightFactor:(CGFloat)newValue;
{
    hasOverriddenImageSizeFactor = YES;
    _imageHeightFactor = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [secondFilterProgram use];
    glUniform1f(imageHeightFactorUniform, 1.0 / _imageHeightFactor);
}

@end


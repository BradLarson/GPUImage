#import "GPUImageSobelEdgeDetectionFilter.h"
#import "GPUImageGrayscaleFilter.h"
#import "GPUImage3x3ConvolutionFilter.h"

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
    float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
    float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
    float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
    
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

    if (!(self = [super initWithFirstStageVertexShaderFromString:kGPUImageVertexShaderString firstStageFragmentShaderFromString:kGPUImageLuminanceFragmentShaderString secondStageVertexShaderFromString:kGPUImageNearbyTexelSamplingVertexShaderString secondStageFragmentShaderFromString:fragmentShaderString]))
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


#import "GPUImageToonFilter.h"
#import "GPUImageSobelEdgeDetectionFilter.h"

// Code from "Graphics Shaders: Theory and Practice" by M. Bailey and S. Cunningham 
NSString *const kGPUImageToonFragmentShaderString = SHADER_STRING
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
 
 uniform highp float intensity;
 
 const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);
 
 const highp float threshold = 0.2;
 const highp float quantize = 10.0;

 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     float i00   = textureColor.g;
     float im1m1 = texture2D(inputImageTexture, bottomLeftTextureCoordinate).g;
     float ip1p1 = texture2D(inputImageTexture, topRightTextureCoordinate).g;
     float im1p1 = texture2D(inputImageTexture, topLeftTextureCoordinate).g;
     float ip1m1 = texture2D(inputImageTexture, bottomRightTextureCoordinate).g;
     float im10 = texture2D(inputImageTexture, leftTextureCoordinate).g;
     float ip10 = texture2D(inputImageTexture, rightTextureCoordinate).g;
     float i0m1 = texture2D(inputImageTexture, bottomTextureCoordinate).g;
     float i0p1 = texture2D(inputImageTexture, topTextureCoordinate).g;
     float h = -im1p1 - 2.0 * i0p1 - ip1p1 + im1m1 + 2.0 * i0m1 + ip1m1;
     float v = -im1m1 - 2.0 * im10 - im1p1 + ip1m1 + 2.0 * ip10 + ip1p1;
     
     float mag = length(vec2(h, v));

     vec3 posterizedImageColor = floor((textureColor.rgb * quantize) + 0.5) / quantize;
     
     float thresholdTest = 1.0 - step(threshold, mag);
     
     gl_FragColor = vec4(posterizedImageColor * thresholdTest, textureColor.a);

     /*
     if (mag > threshold)
     {
         gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
     }
     else
     {
         textureColor *= vec3(quantize);
         textureColor += vec3(0.5);
         textureColor = floor(textureColor) / quantize;
         gl_FragColor = vec4(textureColor, texture2D(inputImageTexture, topTextureCoordinate).w);
     }
      */
 }
);

@implementation GPUImageToonFilter

@synthesize imageWidthFactor = _imageWidthFactor; 
@synthesize imageHeightFactor = _imageHeightFactor; 

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageSobelEdgeDetectionVertexShaderString fragmentShaderFromString:kGPUImageToonFragmentShaderString]))
    {
		return nil;
    }
    
    hasOverriddenImageSizeFactor = NO;
    
    imageWidthFactorUniform = [filterProgram uniformIndex:@"imageWidthFactor"];
    imageHeightFactorUniform = [filterProgram uniformIndex:@"imageHeightFactor"];
    
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


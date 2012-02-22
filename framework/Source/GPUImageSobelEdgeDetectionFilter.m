#import "GPUImageSobelEdgeDetectionFilter.h"

//   Code from "Graphics Shaders: Theory and Practice" by M. Bailey and S. Cunningham 
NSString *const kGPUImageSobelEdgeDetectionFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform mediump float intensity;
 uniform mediump float imageWidthFactor; 
 uniform mediump float imageHeightFactor; 
 
 const mediump vec3 W = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
    mediump vec3 textureColor = texture2D(inputImageTexture, textureCoordinate).rgb;
    
    mediump vec2 stp0 = vec2(1.0 / imageWidthFactor, 0.0);
    mediump vec2 st0p = vec2(0.0, 1.0 / imageHeightFactor);
    mediump vec2 stpp = vec2(1.0 / imageWidthFactor, 1.0 / imageHeightFactor);
    mediump vec2 stpm = vec2(1.0 / imageWidthFactor, -1.0 / imageHeightFactor);
    
    mediump float i00   = dot( textureColor, W);
    mediump float im1m1 = dot( texture2D(inputImageTexture, textureCoordinate - stpp).rgb, W);
    mediump float ip1p1 = dot( texture2D(inputImageTexture, textureCoordinate + stpp).rgb, W);
    mediump float im1p1 = dot( texture2D(inputImageTexture, textureCoordinate - stpm).rgb, W);
    mediump float ip1m1 = dot( texture2D(inputImageTexture, textureCoordinate + stpm).rgb, W);
    mediump float im10 = dot( texture2D(inputImageTexture, textureCoordinate - stp0).rgb, W);
    mediump float ip10 = dot( texture2D(inputImageTexture, textureCoordinate + stp0).rgb, W);
    mediump float i0m1 = dot( texture2D(inputImageTexture, textureCoordinate - st0p).rgb, W);
    mediump float i0p1 = dot( texture2D(inputImageTexture, textureCoordinate + st0p).rgb, W);
    mediump float h = -im1p1 - 2.0 * i0p1 - ip1p1 + im1m1 + 2.0 * i0m1 + ip1m1;
    mediump float v = -im1m1 - 2.0 * im10 - im1p1 + ip1m1 + 2.0 * ip10 + ip1p1;
    
    mediump float mag = length(vec2(h, v));
    mediump vec3 target = vec3(mag);
    
    gl_FragColor = vec4(mix(textureColor, target, intensity), 1.0);
 }
);

@implementation GPUImageSobelEdgeDetectionFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSobelEdgeDetectionFragmentShaderString]))
    {
		return nil;
    }
    
    intensityUniform = [filterProgram uniformIndex:@"intensity"];
    imageWidthFactorUniform = [filterProgram uniformIndex:@"imageWidthFactor"];
    imageHeightFactorUniform = [filterProgram uniformIndex:@"imageHeightFactor"];
    self.intensity = 1.0;
    self.imageWidthFactor = 480.0;
    self.imageHeightFactor = 640.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

@synthesize intensity = _intensity; 
@synthesize imageWidthFactor = _imageWidthFactor; 
@synthesize imageHeightFactor = _imageHeightFactor; 

- (void)setIntensity:(CGFloat)newValue;
{
    _intensity = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(intensityUniform, _intensity);
}

- (void)setImageWidthFactor:(CGFloat)newValue;
{
    _imageWidthFactor = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(imageWidthFactorUniform, _imageWidthFactor);
}

- (void)setImageHeightFactor:(CGFloat)newValue;
{
    _imageHeightFactor = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(imageHeightFactorUniform, _imageHeightFactor);
}

@end


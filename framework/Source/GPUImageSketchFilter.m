#import "GPUImageSketchFilter.h"

@implementation GPUImageSketchFilter

// Invert the colorspace for a sketch
NSString *const kGPUImageSketchFragmentShaderString = SHADER_STRING
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
     
     float mag = 1.0 - length(vec2(h, v));
     
     gl_FragColor = vec4(vec3(mag), 1.0);
 }
);

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kGPUImageSketchFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


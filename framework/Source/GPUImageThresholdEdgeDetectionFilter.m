#import "GPUImageThresholdEdgeDetectionFilter.h"

@implementation GPUImageThresholdEdgeDetectionFilter

// Invert the colorspace for a sketch
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageThresholdEdgeDetectionFragmentShaderString = SHADER_STRING
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
 uniform lowp float threshold;
 
 uniform float edgeStrength;

 void main()
 {
//     float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
//     float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
//     float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
//     float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
     float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
     float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
     float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
     float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
     float centerIntensity = texture2D(inputImageTexture, textureCoordinate).r;
//     float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
//     float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
//     float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + leftIntensity + 2.0 * centerIntensity + rightIntensity;
//     float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomIntensity + 2.0 * centerIntensity + topIntensity;
     float h = (centerIntensity - topIntensity) + (bottomIntensity - centerIntensity);
     float v = (centerIntensity - leftIntensity) + (rightIntensity - centerIntensity);
//     float h = (centerIntensity - topIntensity);
//     float j = (topIntensity - centerIntensity);
//     h = max(h,j);
//     j = abs(h);
//     float v = (centerIntensity - leftIntensity);
     
    float mag = length(vec2(h, v)) * edgeStrength;
     mag = step(threshold, mag);
     
//     float mag = abs(h);
     
//     gl_FragColor = vec4(h, h, h, 1.0);
//     gl_FragColor = vec4(texture2D(inputImageTexture, textureCoordinate));
//     gl_FragColor = vec4(h, centerIntensity, j, 1.0);
     gl_FragColor = vec4(mag, mag, mag, 1.0);
 }
);
#else
NSString *const kGPUImageThresholdEdgeDetectionFragmentShaderString = SHADER_STRING
(
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
 uniform float threshold;
 
 uniform float edgeStrength;

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
     h = max(0.0, h);
     float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
     v = max(0.0, v);
     
     float mag = length(vec2(h, v)) * edgeStrength;
     mag = step(threshold, mag);
     
     gl_FragColor = vec4(vec3(mag), 1.0);
 }
);
#endif

#pragma mark -
#pragma mark Initialization and teardown

@synthesize threshold = _threshold;

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super initWithFragmentShaderFromString:fragmentShaderString]))
    {
		return nil;
    }
    
    thresholdUniform = [secondFilterProgram uniformIndex:@"threshold"];
    self.threshold = 0.25;
    self.edgeStrength = 1.0;
    
    return self;
}


- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kGPUImageThresholdEdgeDetectionFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setThreshold:(CGFloat)newValue;
{
    _threshold = newValue;
    
    [self setFloat:_threshold forUniform:thresholdUniform program:secondFilterProgram];
}

@end

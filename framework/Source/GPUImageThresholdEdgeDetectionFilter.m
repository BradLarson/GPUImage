#import "GPUImageThresholdEdgeDetectionFilter.h"

@implementation GPUImageThresholdEdgeDetectionFilter

// Invert the colorspace for a sketch
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
 
 const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);
 
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
     mag = step(threshold, mag);
     
     gl_FragColor = vec4(vec3(mag), 1.0);
 }
 );

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
    self.threshold = 0.9;
    
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

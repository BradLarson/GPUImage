#import "GPUImageThresholdedNonMaximumSuppressionFilter.h"

NSString *const kGPUImageThresholdedNonMaximumSuppressionFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 leftTextureCoordinate;
 varying highp vec2 rightTextureCoordinate;
 
 varying highp vec2 topTextureCoordinate;
 varying highp vec2 topLeftTextureCoordinate;
 varying highp vec2 topRightTextureCoordinate;
 
 varying highp vec2 bottomTextureCoordinate;
 varying highp vec2 bottomLeftTextureCoordinate;
 varying highp vec2 bottomRightTextureCoordinate;
 
 uniform lowp float threshold;
 
 void main()
 {
     lowp float bottomColor = texture2D(inputImageTexture, bottomTextureCoordinate).r;
     lowp float bottomLeftColor = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
     lowp float bottomRightColor = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
     lowp vec4 centerColor = texture2D(inputImageTexture, textureCoordinate);
     lowp float leftColor = texture2D(inputImageTexture, leftTextureCoordinate).r;
     lowp float rightColor = texture2D(inputImageTexture, rightTextureCoordinate).r;
     lowp float topColor = texture2D(inputImageTexture, topTextureCoordinate).r;
     lowp float topRightColor = texture2D(inputImageTexture, topRightTextureCoordinate).r;
     lowp float topLeftColor = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
     
     // Use a tiebreaker for pixels to the left and immediately above this one
     lowp float multiplier = 1.0 - step(centerColor.r, topColor);
     multiplier = multiplier * 1.0 - step(centerColor.r, topLeftColor);
     multiplier = multiplier * 1.0 - step(centerColor.r, leftColor);
     multiplier = multiplier * 1.0 - step(centerColor.r, bottomLeftColor);
     
     lowp float maxValue = max(centerColor.r, bottomColor);
     maxValue = max(maxValue, bottomRightColor);
     maxValue = max(maxValue, rightColor);
     maxValue = max(maxValue, topRightColor);
     
     lowp float finalValue = centerColor.r * step(maxValue, centerColor.r) * multiplier;
     finalValue = step(threshold, finalValue);
     
     gl_FragColor = vec4(finalValue, finalValue, finalValue, 1.0);
//
//     gl_FragColor = vec4((centerColor.rgb * step(maxValue, step(threshold, centerColor.r)) * multiplier), 1.0);
 }
);


@implementation GPUImageThresholdedNonMaximumSuppressionFilter

@synthesize threshold = _threshold;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageThresholdedNonMaximumSuppressionFragmentShaderString]))
    {
        return nil;
    }
    
    thresholdUniform = [filterProgram uniformIndex:@"threshold"];
    self.threshold = 0.9;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setThreshold:(CGFloat)newValue;
{
    _threshold = newValue;
    
    [self setFloat:_threshold forUniform:thresholdUniform program:filterProgram];
}

@end

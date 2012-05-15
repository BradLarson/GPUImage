#import "GPUImageNonMaximumSuppressionFilter.h"

NSString *const kGPUImageNonMaximumSuppressionFragmentShaderString = SHADER_STRING
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
     
     lowp float maxValue = max(centerColor.r, bottomColor);
     maxValue = max(maxValue, bottomLeftColor);
     maxValue = max(maxValue, bottomRightColor);
     maxValue = max(maxValue, leftColor);
     maxValue = max(maxValue, rightColor);
     maxValue = max(maxValue, topColor);
     maxValue = max(maxValue, topRightColor);
     maxValue = max(maxValue, topLeftColor);
     
     gl_FragColor = vec4((centerColor.rgb * step(maxValue, centerColor.r)), 1.0);
 }
);

@implementation GPUImageNonMaximumSuppressionFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageNonMaximumSuppressionFragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

@end


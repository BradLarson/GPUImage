#import "GPUImagePolkaDotFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImagePolkaDotFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp float fractionalWidthOfPixel;
 uniform highp float aspectRatio;
 uniform highp float dotScaling;
 
 void main()
 {
     highp vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / aspectRatio);
     
     highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor) + 0.5 * sampleDivisor;
     highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     highp vec2 adjustedSamplePos = vec2(samplePos.x, (samplePos.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     highp float distanceFromSamplePoint = distance(adjustedSamplePos, textureCoordinateToUse);
     lowp float checkForPresenceWithinDot = step(distanceFromSamplePoint, (fractionalWidthOfPixel * 0.5) * dotScaling);

     lowp vec4 inputColor = texture2D(inputImageTexture, samplePos);
     
     gl_FragColor = vec4(inputColor.rgb * checkForPresenceWithinDot, inputColor.a);
 }
);
#else
NSString *const kGPUImagePolkaDotFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform float fractionalWidthOfPixel;
 uniform float aspectRatio;
 uniform float dotScaling;
 
 void main()
 {
     vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / aspectRatio);
     
     vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor) + 0.5 * sampleDivisor;
     vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     vec2 adjustedSamplePos = vec2(samplePos.x, (samplePos.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     float distanceFromSamplePoint = distance(adjustedSamplePos, textureCoordinateToUse);
     float checkForPresenceWithinDot = step(distanceFromSamplePoint, (fractionalWidthOfPixel * 0.5) * dotScaling);
     
     vec4 inputColor = texture2D(inputImageTexture, samplePos);

     gl_FragColor = vec4(inputColor.rgb * checkForPresenceWithinDot, inputColor.a);
 }
);
#endif

@implementation GPUImagePolkaDotFilter

@synthesize dotScaling = _dotScaling;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImagePolkaDotFragmentShaderString]))
    {
		return nil;
    }
    
    dotScalingUniform = [filterProgram uniformIndex:@"dotScaling"];
    
    self.dotScaling = 0.90;

    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setDotScaling:(CGFloat)newValue;
{
    _dotScaling = newValue;
    
    [self setFloat:_dotScaling forUniform:dotScalingUniform program:filterProgram];
}

@end

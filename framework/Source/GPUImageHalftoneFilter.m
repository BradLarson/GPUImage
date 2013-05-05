#import "GPUImageHalftoneFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageHalftoneFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp float fractionalWidthOfPixel;
 uniform highp float aspectRatio;
 uniform highp float dotScaling;
 
 const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

 void main()
 {
     highp vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / aspectRatio);
     
     highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor) + 0.5 * sampleDivisor;
     highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     highp vec2 adjustedSamplePos = vec2(samplePos.x, (samplePos.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     highp float distanceFromSamplePoint = distance(adjustedSamplePos, textureCoordinateToUse);
     
     lowp vec3 sampledColor = texture2D(inputImageTexture, samplePos ).rgb;
     highp float dotScaling = 1.0 - dot(sampledColor, W);
    
     lowp float checkForPresenceWithinDot = 1.0 - step(distanceFromSamplePoint, (fractionalWidthOfPixel * 0.5) * dotScaling);
     
     gl_FragColor = vec4(vec3(checkForPresenceWithinDot), 1.0);
 }
);
#else
NSString *const kGPUImageHalftoneFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform float fractionalWidthOfPixel;
 uniform float aspectRatio;
 uniform float dotScaling;
 
 const vec3 W = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / aspectRatio);
     
     vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor) + 0.5 * sampleDivisor;
     vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     vec2 adjustedSamplePos = vec2(samplePos.x, (samplePos.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     float distanceFromSamplePoint = distance(adjustedSamplePos, textureCoordinateToUse);
     
     vec3 sampledColor = texture2D(inputImageTexture, samplePos ).rgb;
     float dotScaling = 1.0 - dot(sampledColor, W);
     
     float checkForPresenceWithinDot = 1.0 - step(distanceFromSamplePoint, (fractionalWidthOfPixel * 0.5) * dotScaling);
     
     gl_FragColor = vec4(vec3(checkForPresenceWithinDot), 1.0);
 }
);
#endif

@implementation GPUImageHalftoneFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageHalftoneFragmentShaderString]))
    {
		return nil;
    }
    
    self.fractionalWidthOfAPixel = 0.01;
    
    return self;
}

@end

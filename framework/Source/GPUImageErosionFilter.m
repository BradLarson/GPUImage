#import "GPUImageErosionFilter.h"

@implementation GPUImageErosionFilter

NSString *const kGPUImageErosionFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
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
     float centerIntensity = texture2D(inputImageTexture, textureCoordinate).r;
     float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
     float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
     float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
     float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
     float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
     float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
     float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
     float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
     
     lowp float minValue = min(centerIntensity, bottomLeftIntensity);
     minValue = min(minValue, topRightIntensity);
     minValue = min(minValue, topLeftIntensity);
     minValue = min(minValue, bottomRightIntensity);
     minValue = min(minValue, leftIntensity);
     minValue = min(minValue, rightIntensity);
     minValue = min(minValue, bottomIntensity);
     minValue = min(minValue, topIntensity);
     
     gl_FragColor = vec4(vec3(minValue), 1.0);
 }
 );

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kGPUImageErosionFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}


@end

#import "GPUImageDilationFilter.h"

@implementation GPUImageDilationFilter

NSString *const kGPUImageDilationFragmentShaderString = SHADER_STRING
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
          
     lowp float maxValue = max(centerIntensity, bottomLeftIntensity);
     maxValue = max(maxValue, topRightIntensity);
     maxValue = max(maxValue, topLeftIntensity);
     maxValue = max(maxValue, bottomRightIntensity);
     maxValue = max(maxValue, leftIntensity);
     maxValue = max(maxValue, rightIntensity);
     maxValue = max(maxValue, bottomIntensity);
     maxValue = max(maxValue, topIntensity);

     gl_FragColor = vec4(vec3(maxValue), 1.0);
 }
);

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kGPUImageDilationFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end

#import "GPUImageHistogramGenerator.h"

NSString *const kGPUImageHistogramGeneratorVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 varying float height;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = vec2(inputTextureCoordinate.x, 0.5);
     height = 1.0 - inputTextureCoordinate.y;
 }
);

NSString *const kGPUImageHistogramGeneratorFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp float height;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     lowp vec3 colorChannels = texture2D(inputImageTexture, textureCoordinate).rgb;
     lowp vec3 heightTest = step(height, colorChannels);
     gl_FragColor = vec4(heightTest, 1.0);
 }
);


@implementation GPUImageHistogramGenerator

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageHistogramGeneratorVertexShaderString fragmentShaderFromString:kGPUImageHistogramGeneratorFragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

@end

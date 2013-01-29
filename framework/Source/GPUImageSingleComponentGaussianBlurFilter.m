#import "GPUImageSingleComponentGaussianBlurFilter.h"

@implementation GPUImageSingleComponentGaussianBlurFilter

NSString *const kGPUImageSingleComponentGaussianBlurFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 const lowp int GAUSSIAN_SAMPLES = 9;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main() {
     lowp float sum = 0.0;
     
     sum += texture2D(inputImageTexture, blurCoordinates[0]).r * 0.05;
     sum += texture2D(inputImageTexture, blurCoordinates[1]).r * 0.09;
     sum += texture2D(inputImageTexture, blurCoordinates[2]).r * 0.12;
     sum += texture2D(inputImageTexture, blurCoordinates[3]).r * 0.15;
     sum += texture2D(inputImageTexture, blurCoordinates[4]).r * 0.18;
     sum += texture2D(inputImageTexture, blurCoordinates[5]).r * 0.15;
     sum += texture2D(inputImageTexture, blurCoordinates[6]).r * 0.12;
     sum += texture2D(inputImageTexture, blurCoordinates[7]).r * 0.09;
     sum += texture2D(inputImageTexture, blurCoordinates[8]).r * 0.05;
     
     gl_FragColor = vec4(sum, sum, sum, 1.0);
 }
);

- (id)init;
{
    
    if (!(self = [super initWithFirstStageVertexShaderFromString:nil
                              firstStageFragmentShaderFromString:kGPUImageSingleComponentGaussianBlurFragmentShaderString
                               secondStageVertexShaderFromString:nil
                             secondStageFragmentShaderFromString:kGPUImageSingleComponentGaussianBlurFragmentShaderString])) 
    {
        return nil;
    }
    
    
    return self;
}

@end

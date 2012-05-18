#import "GPUImageBilateralFilter.h"

NSString *const kGPUImageBilateralFilterFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 const lowp int GAUSSIAN_SAMPLES = 9;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 const mediump float distanceNormalizationFactor = 0.6933613;
 
 void main() {
     lowp vec4 centralColor = texture2D(inputImageTexture, blurCoordinates[4]);
     lowp float gaussianWeightTotal = 0.18;
     lowp vec4 sum = centralColor * 0.18;
     
     lowp vec4 sampleColor = texture2D(inputImageTexture, blurCoordinates[0]);
//     lowp float distanceFromCentralColor = distance(centralColor, sampleColor) * distanceNormalizationFactor;
     lowp float distanceFromCentralColor = abs(centralColor.g - sampleColor.g);
     lowp float gaussianWeight = 0.05 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;

     sampleColor = texture2D(inputImageTexture, blurCoordinates[1]);
//     distanceFromCentralColor = distance(centralColor, sampleColor) * distanceNormalizationFactor;
     distanceFromCentralColor = abs(centralColor.g - sampleColor.g);
     gaussianWeight = 0.09 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;

     sampleColor = texture2D(inputImageTexture, blurCoordinates[2]);
//     distanceFromCentralColor = distance(centralColor, sampleColor) * distanceNormalizationFactor;
     distanceFromCentralColor = abs(centralColor.g - sampleColor.g);
     gaussianWeight = 0.12 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;

     sampleColor = texture2D(inputImageTexture, blurCoordinates[3]);
//     distanceFromCentralColor = distance(centralColor, sampleColor) * distanceNormalizationFactor;
     distanceFromCentralColor = abs(centralColor.g - sampleColor.g);
     gaussianWeight = 0.15 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;

     sampleColor = texture2D(inputImageTexture, blurCoordinates[5]);
//     distanceFromCentralColor = distance(centralColor, sampleColor) * distanceNormalizationFactor;
     distanceFromCentralColor = abs(centralColor.g - sampleColor.g);
     gaussianWeight = 0.15 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;

     sampleColor = texture2D(inputImageTexture, blurCoordinates[6]);
//     distanceFromCentralColor = distance(centralColor, sampleColor) * distanceNormalizationFactor;
     distanceFromCentralColor = abs(centralColor.g - sampleColor.g);
     gaussianWeight = 0.12 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;

     sampleColor = texture2D(inputImageTexture, blurCoordinates[7]);
//     distanceFromCentralColor = distance(centralColor, sampleColor) * distanceNormalizationFactor;
     distanceFromCentralColor = abs(centralColor.g - sampleColor.g);
     gaussianWeight = 0.09 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;

     sampleColor = texture2D(inputImageTexture, blurCoordinates[8]);
//     distanceFromCentralColor = distance(centralColor, sampleColor) * distanceNormalizationFactor;
     distanceFromCentralColor = abs(centralColor.g - sampleColor.g);
     gaussianWeight = 0.05 * (1.0 - distanceFromCentralColor);
     gaussianWeightTotal += gaussianWeight;
     sum += sampleColor * gaussianWeight;
     
     gl_FragColor = sum / gaussianWeightTotal;
 }
);

@implementation GPUImageBilateralFilter

- (id)init;
{
    
    if (!(self = [super initWithFirstStageVertexShaderFromString:nil
                              firstStageFragmentShaderFromString:kGPUImageBilateralFilterFragmentShaderString
                               secondStageVertexShaderFromString:nil
                             secondStageFragmentShaderFromString:kGPUImageBilateralFilterFragmentShaderString])) {
        return nil;
    }
    
    
    return self;
}

@end

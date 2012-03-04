#import "GPUImageGaussianBlurFilter.h"

NSString *const kGPUImageGaussianBlurHorizontalVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 const lowp int GAUSSIAN_SAMPLES = 9;
 
 uniform highp float blurSize;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main() {
 	gl_Position = position;
 	textureCoordinate = inputTextureCoordinate.xy;
 	
 	// Calculate the positions for the blur
 	lowp int multiplier = 0;
 	mediump vec2 blurStep = vec2(0.0, 0.0);
 	for (lowp int i = 0; i < GAUSSIAN_SAMPLES; i++) {
 		multiplier = (i - ((GAUSSIAN_SAMPLES - 1) / 2));
        // Blur in x (horizontal)
        blurStep = vec2(float(multiplier) * blurSize, 0.0);
 		blurCoordinates[i] = inputTextureCoordinate.xy + blurStep;
 	}
 }
);

NSString *const kGPUImageGaussianBlurVerticalVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 const lowp int GAUSSIAN_SAMPLES = 9;
 
 uniform highp float blurSize;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main() {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
     
     // Calculate the positions for the blur
     lowp int multiplier = 0;
     mediump vec2 blurStep = vec2(0.0, 0.0);
     for (lowp int i = 0; i < GAUSSIAN_SAMPLES; i++) {
         multiplier = (i - ((GAUSSIAN_SAMPLES - 1) / 2));
         // Blur in y (vertical)
         blurStep = vec2(0.0, float(multiplier) * blurSize);
         blurCoordinates[i] = inputTextureCoordinate.xy + blurStep;
     }
 }
 );

NSString *const kGPUImageGaussianBlurFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 const lowp int GAUSSIAN_SAMPLES = 9;
 
 uniform mediump float gaussianValues[9];
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main() {
 	highp vec4 sum = vec4(0.0);
 	
 	for (lowp int i = 0; i < GAUSSIAN_SAMPLES; i++) {
 		sum += texture2D(inputImageTexture, blurCoordinates[i]) * gaussianValues[i];
 	}
 	
 	gl_FragColor = sum;
 }
);

@implementation GPUImageGaussianBlurFilter

@synthesize blurSize = _blurSize;

- (id) initWithFirstStageVertexShaderFromString:(NSString *)firstStageVertexShaderString 
             firstStageFragmentShaderFromString:(NSString *)firstStageFragmentShaderString 
              secondStageVertexShaderFromString:(NSString *)secondStageVertexShaderString
            secondStageFragmentShaderFromString:(NSString *)secondStageFragmentShaderString {
    
    if (!(self = [super initWithFirstStageVertexShaderFromString:firstStageVertexShaderString ? firstStageVertexShaderString : kGPUImageGaussianBlurHorizontalVertexShaderString
                              firstStageFragmentShaderFromString:firstStageFragmentShaderString ? firstStageFragmentShaderString : kGPUImageGaussianBlurFragmentShaderString
                               secondStageVertexShaderFromString:secondStageVertexShaderString ? secondStageVertexShaderString : kGPUImageGaussianBlurVerticalVertexShaderString
                             secondStageFragmentShaderFromString:secondStageFragmentShaderString ? secondStageFragmentShaderString : kGPUImageGaussianBlurFragmentShaderString])) {
        return nil;
    }
    
    horizontalBlurSizeUniform = [filterProgram uniformIndex:@"blurSize"];
    horizontalGaussianArrayUniform = [filterProgram uniformIndex:@"gaussianValues"];
    
    verticalBlurSizeUniform = [secondFilterProgram uniformIndex:@"blurSize"];
    verticalGaussianArrayUniform = [secondFilterProgram uniformIndex:@"gaussianValues"];
    
    self.blurSize = 1.0/320.0;
    [self setGaussianValues];
    
    return self;
}

- (id)init;
{
    return [self initWithFirstStageVertexShaderFromString:nil
                       firstStageFragmentShaderFromString:nil
                        secondStageVertexShaderFromString:nil
                      secondStageFragmentShaderFromString:nil];
}

#pragma mark Getters and Setters

- (void) setGaussianValues {
    GLsizei gaussianLength = 9;
    GLfloat gaussians[] = { 0.05, 0.09, 0.12, 0.15, 0.18, 0.15, 0.12, 0.09, 0.05 };
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1fv(horizontalGaussianArrayUniform, gaussianLength, gaussians);
    
    [secondFilterProgram use];
    glUniform1fv(verticalGaussianArrayUniform, gaussianLength, gaussians);
}

- (void) setBlurSize:(CGFloat)blurSize {
    _blurSize = blurSize;

    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(horizontalBlurSizeUniform, _blurSize);
    
    [secondFilterProgram use];
    glUniform1f(verticalBlurSizeUniform, _blurSize);
}

@end

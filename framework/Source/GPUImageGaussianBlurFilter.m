#import "GPUImageGaussianBlurFilter.h"

NSString *const kGPUImageGaussianBlurVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 const lowp int GAUSSIAN_SAMPLES = 9;
 
 uniform highp float texelWidthOffset; 
 uniform highp float texelHeightOffset;
 uniform highp float blurSize;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main() {
 	gl_Position = position;
 	textureCoordinate = inputTextureCoordinate.xy;
 	
 	// Calculate the positions for the blur
 	int multiplier = 0;
 	highp vec2 blurStep;
    highp vec2 singleStepOffset = vec2(texelHeightOffset, texelWidthOffset) * blurSize;
     
 	for (lowp int i = 0; i < GAUSSIAN_SAMPLES; i++) {
 		multiplier = (i - ((GAUSSIAN_SAMPLES - 1) / 2));
        // Blur in x (horizontal)
        blurStep = float(multiplier) * singleStepOffset;
 		blurCoordinates[i] = inputTextureCoordinate.xy + blurStep;
 	}
 }
);

NSString *const kGPUImageGaussianBlurFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 const lowp int GAUSSIAN_SAMPLES = 9;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main() {
 	lowp vec4 sum = vec4(0.0);
 	
     sum += texture2D(inputImageTexture, blurCoordinates[0]) * 0.05;
     sum += texture2D(inputImageTexture, blurCoordinates[1]) * 0.09;
     sum += texture2D(inputImageTexture, blurCoordinates[2]) * 0.12;
     sum += texture2D(inputImageTexture, blurCoordinates[3]) * 0.15;
     sum += texture2D(inputImageTexture, blurCoordinates[4]) * 0.18;
     sum += texture2D(inputImageTexture, blurCoordinates[5]) * 0.15;
     sum += texture2D(inputImageTexture, blurCoordinates[6]) * 0.12;
     sum += texture2D(inputImageTexture, blurCoordinates[7]) * 0.09;
     sum += texture2D(inputImageTexture, blurCoordinates[8]) * 0.05;

 	gl_FragColor = sum;
 }
);

@implementation GPUImageGaussianBlurFilter

@synthesize blurSize = _blurSize;

- (id) initWithFirstStageVertexShaderFromString:(NSString *)firstStageVertexShaderString 
             firstStageFragmentShaderFromString:(NSString *)firstStageFragmentShaderString 
              secondStageVertexShaderFromString:(NSString *)secondStageVertexShaderString
            secondStageFragmentShaderFromString:(NSString *)secondStageFragmentShaderString {
    
    if (!(self = [super initWithFirstStageVertexShaderFromString:firstStageVertexShaderString ? firstStageVertexShaderString : kGPUImageGaussianBlurVertexShaderString
                              firstStageFragmentShaderFromString:firstStageFragmentShaderString ? firstStageFragmentShaderString : kGPUImageGaussianBlurFragmentShaderString
                               secondStageVertexShaderFromString:secondStageVertexShaderString ? secondStageVertexShaderString : kGPUImageGaussianBlurVertexShaderString
                             secondStageFragmentShaderFromString:secondStageFragmentShaderString ? secondStageFragmentShaderString : kGPUImageGaussianBlurFragmentShaderString])) {
        return nil;
    }
    
    horizontalBlurSizeUniform = [filterProgram uniformIndex:@"blurSize"];
    horizontalGaussianArrayUniform = [filterProgram uniformIndex:@"gaussianValues"];
    horizontalPassTexelWidthOffsetUniform = [filterProgram uniformIndex:@"texelWidthOffset"];
    horizontalPassTexelHeightOffsetUniform = [filterProgram uniformIndex:@"texelHeightOffset"];

    verticalBlurSizeUniform = [secondFilterProgram uniformIndex:@"blurSize"];
    verticalGaussianArrayUniform = [secondFilterProgram uniformIndex:@"gaussianValues"];
    verticalPassTexelWidthOffsetUniform = [secondFilterProgram uniformIndex:@"texelWidthOffset"];
    verticalPassTexelHeightOffsetUniform = [secondFilterProgram uniformIndex:@"texelHeightOffset"];

    self.blurSize = 1.0;
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

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(horizontalPassTexelWidthOffsetUniform, 1.0 / filterFrameSize.width);
    glUniform1f(horizontalPassTexelHeightOffsetUniform, 0.0);

    [secondFilterProgram use];
    glUniform1f(verticalPassTexelWidthOffsetUniform, 0.0);
    glUniform1f(verticalPassTexelHeightOffsetUniform, 1.0 / filterFrameSize.height);
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

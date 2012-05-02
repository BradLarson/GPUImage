#import "GPUImageGaussianSelectiveBlurFilter.h"

NSString *const kGPUImageGaussianSelectiveBlurVerticalFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; // The un-blurred image
 
 const lowp int GAUSSIAN_SAMPLES = 9;
 
 uniform lowp float excludeCircleRadius;
 uniform lowp vec2 excludeCirclePoint;
 uniform lowp float excludeBlurSize;
 
 uniform mediump float gaussianValues[9];
 
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

     lowp vec4 overlay = texture2D(inputImageTexture2, textureCoordinate);
     lowp float d = distance(textureCoordinate, excludeCirclePoint);
     
     sum = mix(overlay, sum, smoothstep(excludeCircleRadius - excludeBlurSize, excludeCircleRadius, d));

 	gl_FragColor = sum;
 }
);

@implementation GPUImageGaussianSelectiveBlurFilter

@synthesize excludeCirclePoint = _excludeCirclePoint, excludeCircleRadius = _excludeCircleRadius, excludeBlurSize = _excludeBlurSize;

- (id)init;
{
    if (!(self = [super initWithFirstStageVertexShaderFromString:nil
                              firstStageFragmentShaderFromString:nil
                               secondStageVertexShaderFromString:nil
                             secondStageFragmentShaderFromString:kGPUImageGaussianSelectiveBlurVerticalFragmentShaderString])) {
        return nil;
    }
    
    verticalExcludeCircleBlurSizeUniform = [secondFilterProgram uniformIndex:@"excludeBlurSize"];
    verticalExcludeCirclePointUniform = [secondFilterProgram uniformIndex:@"excludeCirclePoint"];
    verticalExcludeCircleRadiusUniform = [secondFilterProgram uniformIndex:@"excludeCircleRadius"];
    
    // Set up defaults
    
    self.blurSize = 2.0;

    self.excludeCircleRadius = 60.0/320.0;
    self.excludeCirclePoint = CGPointMake(0.5f, 0.5f);
    self.excludeBlurSize = 30.0/320.0;
    
    return self;
}

- (void) setInputTexture:(GLuint)newInputTexture atIndex:(NSInteger)textureIndex {
    if (textureIndex == 0) {
        [super setInputTexture:newInputTexture atIndex:0];
        [super setInputTexture:newInputTexture atIndex:1];
    }
}

#pragma mark Getters and Setters

- (void) setExcludeCirclePoint:(CGPoint)excludeCirclePoint {
    _excludeCirclePoint = excludeCirclePoint;
    
    GLfloat excludeCirclePosition[2];
    excludeCirclePosition[0] = _excludeCirclePoint.x;
    excludeCirclePosition[1] = _excludeCirclePoint.y;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [secondFilterProgram use];
    
    glUniform2fv(verticalExcludeCirclePointUniform, 1, excludeCirclePosition);
}

- (void) setExcludeCircleRadius:(CGFloat)excludeCircleRadius {
    _excludeCircleRadius = excludeCircleRadius;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [secondFilterProgram use];
    
    glUniform1f(verticalExcludeCircleRadiusUniform, _excludeCircleRadius);
}

- (void) setExcludeBlurSize:(CGFloat)excludeBlurSize {
    _excludeBlurSize = excludeBlurSize;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [secondFilterProgram use];
    
    glUniform1f(verticalExcludeCircleBlurSizeUniform, _excludeBlurSize);
}

@end

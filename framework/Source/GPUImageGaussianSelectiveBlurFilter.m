#import "GPUImageGaussianSelectiveBlurFilter.h"

NSString *const kGPUImageGaussianSelectiveBlurVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 const lowp int GAUSSIAN_SAMPLES = 9;

 uniform highp float blurSize;
 uniform lowp int horizontalBlur; // 0 == vertical blur, 1 == horizontal blur
 
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
 		if (horizontalBlur == 1) {
 			// Blur in x (horizontal)
 			blurStep = vec2(float(multiplier) * blurSize, 0.0);
 		} else {
 			// Blur in y (vertical)
 			blurStep = vec2(0.0, float(multiplier) * blurSize);
 		}
 		blurCoordinates[i] = inputTextureCoordinate.xy + blurStep;
 	}
 }
);

NSString *const kGPUImageGaussianSelectiveBlurFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; // The un-blurred image
 
 const lowp int GAUSSIAN_SAMPLES = 9;
 
 uniform lowp float excludeCircleRadius;
 uniform lowp vec2 excludeCirclePoint;
 uniform lowp float excludeBlurSize;
 
 uniform mediump float gaussianValues[9];
 uniform lowp int horizontalBlur; // 0 == vertical blur, 1 == horizontal blur
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main() {
     
    highp vec4 sum = vec4(0.0);
 	
 	for (lowp int i = 0; i < GAUSSIAN_SAMPLES; i++) {
 		sum += texture2D(inputImageTexture, blurCoordinates[i]) * gaussianValues[i];
 	}
 	
     if (horizontalBlur == 0) {
         highp vec4 overlay = texture2D(inputImageTexture2, textureCoordinate);
         lowp float d = distance(textureCoordinate, excludeCirclePoint);
         
         sum = mix(overlay, sum, smoothstep(excludeCircleRadius - excludeBlurSize, excludeCircleRadius, d));
     }
     
 	gl_FragColor = sum;
 }
);

@implementation GPUImageGaussianSelectiveBlurFilter

@synthesize excludeCirclePoint=_excludeCirclePoint, excludeCircleRadius=_excludeCircleRadius, excludeBlurSize=_excludeBlurSize;

- (id)init;
{
    if (!(self = [super initWithGaussianVertexShaderFromString:kGPUImageGaussianSelectiveBlurVertexShaderString fragmentShaderFromString:kGPUImageGaussianSelectiveBlurFragmentShaderString]))
    {
		return nil;
    }
    
    // Pass the original texture as the 2nd to the vertical blur for the selective
    [self addTarget:verticalBlur];
    
    self.blurSize = 1.0/320.0;

    self.excludeCircleRadius = 60.0/320.0;
    self.excludeCirclePoint = CGPointMake(0.5f, 0.5f);
    self.excludeBlurSize = 20.0/320.0;
    
    return self;
}

#pragma mark Getters and Setters

- (void) setExcludeCirclePoint:(CGPoint)excludeCirclePoint {
    _excludeCirclePoint = excludeCirclePoint;
    
    [horizontalBlur setPoint:_excludeCirclePoint forUniform:@"excludeCirclePoint"];
    [verticalBlur setPoint:_excludeCirclePoint forUniform:@"excludeCirclePoint"];
}

- (void) setExcludeCircleRadius:(CGFloat)excludeCircleRadius {
    _excludeCircleRadius = excludeCircleRadius;
    
    [horizontalBlur setFloat:_excludeCircleRadius forUniform:@"excludeCircleRadius"];
    [verticalBlur setFloat:_excludeCircleRadius forUniform:@"excludeCircleRadius"];
}

- (void) setExcludeBlurSize:(CGFloat)excludeBlurSize {
    _excludeBlurSize = excludeBlurSize;
    
    [horizontalBlur setFloat:_excludeBlurSize forUniform:@"excludeBlurSize"];
    [verticalBlur setFloat:_excludeBlurSize forUniform:@"excludeBlurSize"];
}

@end

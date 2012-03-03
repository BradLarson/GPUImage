#import "GPUImageGaussianBlurFilter.h"

// To pass through
NSString *const kGPUImageGaussianBlurPassThroughFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying highp vec2 textureCoordinate;
 
 void main() {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);

NSString *const kGPUImageGaussianBlurVertexShaderString = SHADER_STRING
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

@synthesize blurSize=_blurSize;

- (id) initWithGaussianVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString {
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageGaussianBlurPassThroughFragmentShaderString])) {
        return nil;
    }
    
    horizontalBlur = [[GPUImageFilter alloc] initWithVertexShaderFromString:vertexShaderString fragmentShaderFromString:fragmentShaderString];
    [horizontalBlur setInteger:1 forUniform:@"horizontalBlur"];
    
    verticalBlur = [[GPUImageFilter alloc] initWithVertexShaderFromString:vertexShaderString fragmentShaderFromString:fragmentShaderString];
    [verticalBlur setInteger:0 forUniform:@"horizontalBlur"];
    
    [self addTarget:horizontalBlur];
    [horizontalBlur addTarget:verticalBlur];
    
    self.blurSize = 1.0/320.0;
    
    [self setGaussianValues];
    
    return self;
}

- (id)init;
{
    return [self initWithGaussianVertexShaderFromString:kGPUImageGaussianBlurVertexShaderString fragmentShaderFromString:kGPUImageGaussianBlurFragmentShaderString];
}

- (void) addTarget:(NSObject<GPUImageInput>*)newTarget {
    if ([newTarget isEqual:horizontalBlur] || [newTarget isEqual:verticalBlur]) [super addTarget:newTarget];
    else [verticalBlur addTarget:newTarget];
}

- (void) removeAllTargets {
    [verticalBlur removeAllTargets];
}

- (void) removeTarget:(id<GPUImageInput>)targetToRemove {
    [verticalBlur removeTarget:targetToRemove];
}

- (UIImage *)imageFromCurrentlyProcessedOutput {
    return [verticalBlur imageFromCurrentlyProcessedOutput];
}

- (UIImage *)imageByFilteringImage:(UIImage *)imageToFilter {
    UIImage *intermediaryImage = [horizontalBlur imageByFilteringImage:imageToFilter];
    return [verticalBlur imageByFilteringImage:intermediaryImage];
}

#pragma mark Getters and Setters

- (void) setGaussianValues {
    GLsizei gaussianLength = 9;
    GLfloat gaussians[] = { 0.05, 0.09, 0.12, 0.15, 0.18, 0.15, 0.12, 0.09, 0.05 };
    
    [horizontalBlur setFloatArray:gaussians length:gaussianLength forUniform:@"gaussianValues"];
    [verticalBlur setFloatArray:gaussians length:gaussianLength forUniform:@"gaussianValues"];
}

- (void) setBlurSize:(CGFloat)blurSize {
    _blurSize = blurSize;

    [horizontalBlur setFloat:_blurSize forUniform:@"blurSize"];
    [verticalBlur setFloat:_blurSize forUniform:@"blurSize"];
}

@end

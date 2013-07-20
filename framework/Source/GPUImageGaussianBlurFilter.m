#import "GPUImageGaussianBlurFilter.h"

NSString *const kGPUImageGaussianBlurVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 const int GAUSSIAN_SAMPLES = 9;
 
 uniform float texelWidthOffset;
 uniform float texelHeightOffset;
 
 varying vec2 textureCoordinate;
 varying vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main()
 {
 	gl_Position = position;
 	textureCoordinate = inputTextureCoordinate.xy;
 	
 	// Calculate the positions for the blur
 	int multiplier = 0;
 	vec2 blurStep;
    vec2 singleStepOffset = vec2(texelWidthOffset, texelHeightOffset);
     
 	for (int i = 0; i < GAUSSIAN_SAMPLES; i++)
    {
 		multiplier = (i - ((GAUSSIAN_SAMPLES - 1) / 2));
        // Blur in x (horizontal)
        blurStep = float(multiplier) * singleStepOffset;
 		blurCoordinates[i] = inputTextureCoordinate.xy + blurStep;
 	}
 }
);

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageGaussianBlurFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 const lowp int GAUSSIAN_SAMPLES = 9;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main()
 {
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
#else
NSString *const kGPUImageGaussianBlurFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 const int GAUSSIAN_SAMPLES = 9;
 
 varying vec2 textureCoordinate;
 varying vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main()
 {
     vec4 sum = vec4(0.0);
     
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
#endif

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
    
    self.blurSize = 1.0;
    
    return self;
}

- (id)init;
{
    return [self initWithFirstStageVertexShaderFromString:nil
                       firstStageFragmentShaderFromString:nil
                        secondStageVertexShaderFromString:nil
                      secondStageFragmentShaderFromString:nil];
}

#pragma mark -
#pragma mark Accessors

- (void)setBlurSize:(CGFloat)newValue;
{
    _blurSize = newValue;
    
    _verticalTexelSpacing = _blurSize;
    _horizontalTexelSpacing = _blurSize;
    
    [self setupFilterForSize:[self sizeOfFBO]];
}


@end

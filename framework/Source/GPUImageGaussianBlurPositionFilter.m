#import "GPUImageGaussianBlurPositionFilter.h"

NSString *const kGPUImageGaussianBlurPositionVertexShaderString = SHADER_STRING
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

NSString *const kGPUImageGaussianBlurPositionFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 const lowp int GAUSSIAN_SAMPLES = 9;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];

 uniform highp float aspectRatio;
 uniform lowp vec2 blurCenter;
 uniform highp float blurRadius;
 
 void main() {
     highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     highp float dist = distance(blurCenter, textureCoordinateToUse);

     if (dist < blurRadius)
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
     else
     {
         gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
     }
 }
);

@interface GPUImageGaussianBlurPositionFilter ()

@property (readwrite, nonatomic) CGFloat aspectRatio;

@end

@implementation GPUImageGaussianBlurPositionFilter

@synthesize blurSize = _blurSize;
@synthesize blurCenter = _blurCenter;
@synthesize aspectRatio = _aspectRatio;

- (id) initWithFirstStageVertexShaderFromString:(NSString *)firstStageVertexShaderString 
             firstStageFragmentShaderFromString:(NSString *)firstStageFragmentShaderString 
              secondStageVertexShaderFromString:(NSString *)secondStageVertexShaderString
            secondStageFragmentShaderFromString:(NSString *)secondStageFragmentShaderString {
    
    if (!(self = [super initWithFirstStageVertexShaderFromString:firstStageVertexShaderString ? firstStageVertexShaderString : kGPUImageGaussianBlurPositionVertexShaderString
                              firstStageFragmentShaderFromString:firstStageFragmentShaderString ? firstStageFragmentShaderString : kGPUImageGaussianBlurPositionFragmentShaderString
                               secondStageVertexShaderFromString:secondStageVertexShaderString ? secondStageVertexShaderString : kGPUImageGaussianBlurPositionVertexShaderString
                             secondStageFragmentShaderFromString:secondStageFragmentShaderString ? secondStageFragmentShaderString : kGPUImageGaussianBlurPositionFragmentShaderString])) {
        return nil;
    }
    
    horizontalBlurSizeUniform = [filterProgram uniformIndex:@"blurSize"];
    verticalBlurSizeUniform = [secondFilterProgram uniformIndex:@"blurSize"];
    aspectRatioUniform = [secondFilterProgram uniformIndex:@"aspectRatio"];
    blurCenterUniform = [secondFilterProgram uniformIndex:@"blurCenter"];
    blurRadiusUniform = [secondFilterProgram uniformIndex:@"blurRadius"];

    self.blurSize = 1.0;
    self.blurRadius = 1.0;
    self.blurCenter = CGPointMake(0.5, 0.5);
    
    return self;
}

- (id)init;
{
    return [self initWithFirstStageVertexShaderFromString:nil
                       firstStageFragmentShaderFromString:nil
                        secondStageVertexShaderFromString:nil
                      secondStageFragmentShaderFromString:nil];
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    CGSize oldInputSize = inputTextureSize;
    [super setInputSize:newSize atIndex:textureIndex];

    if ( (!CGSizeEqualToSize(oldInputSize, inputTextureSize)) && (!CGSizeEqualToSize(newSize, CGSizeZero)) )
    {
        if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
        {
            [self setAspectRatio:(inputTextureSize.width / inputTextureSize.height)];
        }
        else
        {
            [self setAspectRatio:(inputTextureSize.height / inputTextureSize.width)];
        }
    }
}

#pragma mark Getters and Setters

- (void) setBlurSize:(CGFloat)blurSize;
{
    _blurSize = blurSize;

    [self setFloat:_blurSize forUniform:horizontalBlurSizeUniform program:filterProgram];
    [self setFloat:_blurSize forUniform:verticalBlurSizeUniform program:secondFilterProgram];
}

- (void) setBlurCenter:(CGPoint)blurCenter;
{
    _blurCenter = blurCenter;

    [self setPoint:_blurCenter forUniform:blurCenterUniform program:secondFilterProgram];
}

- (void) setBlurRadius:(CGFloat)blurRadius;
{
    _blurRadius = blurRadius;

    [self setFloat:_blurRadius forUniform:blurRadiusUniform program:secondFilterProgram];
}

- (void) setAspectRatio:(CGFloat)newValue;
{
    _aspectRatio = newValue;

    [self setFloat:_aspectRatio forUniform:aspectRatioUniform program:secondFilterProgram];
}

@end

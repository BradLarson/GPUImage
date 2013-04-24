#import "GPUImageMotionBlurFilter.h"

// Override vertex shader to remove dependent texture reads
NSString *const kGPUImageTiltedTexelSamplingVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform vec2 directionalTexelStep;
 
 varying vec2 textureCoordinate;
 varying vec2 oneStepBackTextureCoordinate;
 varying vec2 twoStepsBackTextureCoordinate;
 varying vec2 threeStepsBackTextureCoordinate;
 varying vec2 fourStepsBackTextureCoordinate;
 varying vec2 oneStepForwardTextureCoordinate;
 varying vec2 twoStepsForwardTextureCoordinate;
 varying vec2 threeStepsForwardTextureCoordinate;
 varying vec2 fourStepsForwardTextureCoordinate;
 
 void main()
 {
     gl_Position = position;
     
     textureCoordinate = inputTextureCoordinate.xy;
     oneStepBackTextureCoordinate = inputTextureCoordinate.xy - directionalTexelStep;
     twoStepsBackTextureCoordinate = inputTextureCoordinate.xy - 2.0 * directionalTexelStep;
     threeStepsBackTextureCoordinate = inputTextureCoordinate.xy - 3.0 * directionalTexelStep;
     fourStepsBackTextureCoordinate = inputTextureCoordinate.xy - 4.0 * directionalTexelStep;
     oneStepForwardTextureCoordinate = inputTextureCoordinate.xy + directionalTexelStep;
     twoStepsForwardTextureCoordinate = inputTextureCoordinate.xy + 2.0 * directionalTexelStep;
     threeStepsForwardTextureCoordinate = inputTextureCoordinate.xy + 3.0 * directionalTexelStep;
     fourStepsForwardTextureCoordinate = inputTextureCoordinate.xy + 4.0 * directionalTexelStep;
 }
);

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageMotionBlurFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 uniform sampler2D inputImageTexture;
 
 varying vec2 textureCoordinate;
 varying vec2 oneStepBackTextureCoordinate;
 varying vec2 twoStepsBackTextureCoordinate;
 varying vec2 threeStepsBackTextureCoordinate;
 varying vec2 fourStepsBackTextureCoordinate;
 varying vec2 oneStepForwardTextureCoordinate;
 varying vec2 twoStepsForwardTextureCoordinate;
 varying vec2 threeStepsForwardTextureCoordinate;
 varying vec2 fourStepsForwardTextureCoordinate;
 
 void main()
 {
     // Box weights
//     lowp vec4 fragmentColor = texture2D(inputImageTexture, textureCoordinate) * 0.1111111;
//     fragmentColor += texture2D(inputImageTexture, oneStepBackTextureCoordinate) * 0.1111111;
//     fragmentColor += texture2D(inputImageTexture, twoStepsBackTextureCoordinate) * 0.1111111;
//     fragmentColor += texture2D(inputImageTexture, threeStepsBackTextureCoordinate) * 0.1111111;
//     fragmentColor += texture2D(inputImageTexture, fourStepsBackTextureCoordinate) * 0.1111111;
//     fragmentColor += texture2D(inputImageTexture, oneStepForwardTextureCoordinate) * 0.1111111;
//     fragmentColor += texture2D(inputImageTexture, twoStepsForwardTextureCoordinate) * 0.1111111;
//     fragmentColor += texture2D(inputImageTexture, threeStepsForwardTextureCoordinate) * 0.1111111;
//     fragmentColor += texture2D(inputImageTexture, fourStepsForwardTextureCoordinate) * 0.1111111;

     lowp vec4 fragmentColor = texture2D(inputImageTexture, textureCoordinate) * 0.18;
     fragmentColor += texture2D(inputImageTexture, oneStepBackTextureCoordinate) * 0.15;
     fragmentColor += texture2D(inputImageTexture, twoStepsBackTextureCoordinate) *  0.12;
     fragmentColor += texture2D(inputImageTexture, threeStepsBackTextureCoordinate) * 0.09;
     fragmentColor += texture2D(inputImageTexture, fourStepsBackTextureCoordinate) * 0.05;
     fragmentColor += texture2D(inputImageTexture, oneStepForwardTextureCoordinate) * 0.15;
     fragmentColor += texture2D(inputImageTexture, twoStepsForwardTextureCoordinate) *  0.12;
     fragmentColor += texture2D(inputImageTexture, threeStepsForwardTextureCoordinate) * 0.09;
     fragmentColor += texture2D(inputImageTexture, fourStepsForwardTextureCoordinate) * 0.05;

     gl_FragColor = fragmentColor;
 }
);
#else
NSString *const kGPUImageMotionBlurFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 
 varying vec2 textureCoordinate;
 varying vec2 oneStepBackTextureCoordinate;
 varying vec2 twoStepsBackTextureCoordinate;
 varying vec2 threeStepsBackTextureCoordinate;
 varying vec2 fourStepsBackTextureCoordinate;
 varying vec2 oneStepForwardTextureCoordinate;
 varying vec2 twoStepsForwardTextureCoordinate;
 varying vec2 threeStepsForwardTextureCoordinate;
 varying vec2 fourStepsForwardTextureCoordinate;
 
 void main()
 {
     // Box weights
     //     vec4 fragmentColor = texture2D(inputImageTexture, textureCoordinate) * 0.1111111;
     //     fragmentColor += texture2D(inputImageTexture, oneStepBackTextureCoordinate) * 0.1111111;
     //     fragmentColor += texture2D(inputImageTexture, twoStepsBackTextureCoordinate) * 0.1111111;
     //     fragmentColor += texture2D(inputImageTexture, threeStepsBackTextureCoordinate) * 0.1111111;
     //     fragmentColor += texture2D(inputImageTexture, fourStepsBackTextureCoordinate) * 0.1111111;
     //     fragmentColor += texture2D(inputImageTexture, oneStepForwardTextureCoordinate) * 0.1111111;
     //     fragmentColor += texture2D(inputImageTexture, twoStepsForwardTextureCoordinate) * 0.1111111;
     //     fragmentColor += texture2D(inputImageTexture, threeStepsForwardTextureCoordinate) * 0.1111111;
     //     fragmentColor += texture2D(inputImageTexture, fourStepsForwardTextureCoordinate) * 0.1111111;
     
     vec4 fragmentColor = texture2D(inputImageTexture, textureCoordinate) * 0.18;
     fragmentColor += texture2D(inputImageTexture, oneStepBackTextureCoordinate) * 0.15;
     fragmentColor += texture2D(inputImageTexture, twoStepsBackTextureCoordinate) *  0.12;
     fragmentColor += texture2D(inputImageTexture, threeStepsBackTextureCoordinate) * 0.09;
     fragmentColor += texture2D(inputImageTexture, fourStepsBackTextureCoordinate) * 0.05;
     fragmentColor += texture2D(inputImageTexture, oneStepForwardTextureCoordinate) * 0.15;
     fragmentColor += texture2D(inputImageTexture, twoStepsForwardTextureCoordinate) *  0.12;
     fragmentColor += texture2D(inputImageTexture, threeStepsForwardTextureCoordinate) * 0.09;
     fragmentColor += texture2D(inputImageTexture, fourStepsForwardTextureCoordinate) * 0.05;
     
     gl_FragColor = fragmentColor;
 }
);
#endif

@interface GPUImageMotionBlurFilter()
{
    GLint directionalTexelStepUniform;
}

- (void)recalculateTexelOffsets;

@end

@implementation GPUImageMotionBlurFilter

@synthesize blurSize = _blurSize;
@synthesize blurAngle = _blurAngle;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageTiltedTexelSamplingVertexShaderString fragmentShaderFromString:kGPUImageMotionBlurFragmentShaderString]))
    {
        return nil;
    }
    
    directionalTexelStepUniform = [filterProgram uniformIndex:@"directionalTexelStep"];
    
    self.blurSize = 2.5;
    self.blurAngle = 0.0;
    
    return self;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    CGSize oldInputSize = inputTextureSize;
    [super setInputSize:newSize atIndex:textureIndex];
    
    if (!CGSizeEqualToSize(oldInputSize, inputTextureSize) && (!CGSizeEqualToSize(newSize, CGSizeZero)) )
    {
        [self recalculateTexelOffsets];
    }
}

- (void)recalculateTexelOffsets;
{
    CGFloat aspectRatio = 1.0;
    CGPoint texelOffsets;
    
    if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
    {
        aspectRatio = (inputTextureSize.width / inputTextureSize.height);
        texelOffsets.x = _blurSize * sin(_blurAngle * M_PI / 180.0) * aspectRatio / inputTextureSize.height;
        texelOffsets.y = _blurSize * cos(_blurAngle * M_PI / 180.0) / inputTextureSize.height;
    }
    else
    {
        aspectRatio = (inputTextureSize.height / inputTextureSize.width);
        texelOffsets.x = _blurSize * cos(_blurAngle * M_PI / 180.0) * aspectRatio / inputTextureSize.width;
        texelOffsets.y = _blurSize * sin(_blurAngle * M_PI / 180.0) / inputTextureSize.width;
    }
    
    [self setPoint:texelOffsets forUniform:directionalTexelStepUniform program:filterProgram];
}

#pragma mark -
#pragma mark Accessors

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    [super setInputRotation:newInputRotation atIndex:textureIndex];
    [self recalculateTexelOffsets];
}

- (void)setBlurAngle:(CGFloat)newValue;
{
    _blurAngle = newValue;
    [self recalculateTexelOffsets];
}

- (void)setBlurSize:(CGFloat)newValue;
{
    _blurSize = newValue;
    [self recalculateTexelOffsets];
}


@end

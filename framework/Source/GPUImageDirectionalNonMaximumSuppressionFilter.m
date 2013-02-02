#import "GPUImageDirectionalNonMaximumSuppressionFilter.h"

@implementation GPUImageDirectionalNonMaximumSuppressionFilter

NSString *const kGPUImageDirectionalNonmaximumSuppressionFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform highp float texelWidth; 
 uniform highp float texelHeight; 
 uniform mediump float upperThreshold; 
 uniform mediump float lowerThreshold; 

 void main()
 {
     vec3 currentGradientAndDirection = texture2D(inputImageTexture, textureCoordinate).rgb;
     vec2 gradientDirection = ((currentGradientAndDirection.gb * 2.0) - 1.0) * vec2(texelWidth, texelHeight);
     
     float firstSampledGradientMagnitude = texture2D(inputImageTexture, textureCoordinate + gradientDirection).r;
     float secondSampledGradientMagnitude = texture2D(inputImageTexture, textureCoordinate - gradientDirection).r;
     
     float multiplier = step(firstSampledGradientMagnitude, currentGradientAndDirection.r);
     multiplier = multiplier * step(secondSampledGradientMagnitude, currentGradientAndDirection.r);
     
     float thresholdCompliance = smoothstep(lowerThreshold, upperThreshold, currentGradientAndDirection.r);
     multiplier = multiplier * thresholdCompliance;
     
     gl_FragColor = vec4(multiplier, multiplier, multiplier, 1.0);
 }
);


@synthesize texelWidth = _texelWidth; 
@synthesize texelHeight = _texelHeight; 
@synthesize upperThreshold = _upperThreshold;
@synthesize lowerThreshold = _lowerThreshold;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageDirectionalNonmaximumSuppressionFragmentShaderString]))
    {
        return nil;
    }
    
    texelWidthUniform = [filterProgram uniformIndex:@"texelWidth"];
    texelHeightUniform = [filterProgram uniformIndex:@"texelHeight"];
    upperThresholdUniform = [filterProgram uniformIndex:@"upperThreshold"];
    lowerThresholdUniform = [filterProgram uniformIndex:@"lowerThreshold"];
    
    self.upperThreshold = 0.5;
    self.lowerThreshold = 0.1;
    
    return self;
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    if (!hasOverriddenImageSizeFactor)
    {
        _texelWidth = 1.0 / filterFrameSize.width;
        _texelHeight = 1.0 / filterFrameSize.height;
        
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
            glUniform1f(texelWidthUniform, _texelWidth);
            glUniform1f(texelHeightUniform, _texelHeight);
        });
    }
}

#pragma mark -
#pragma mark Accessors

- (void)setTexelWidth:(CGFloat)newValue;
{
    hasOverriddenImageSizeFactor = YES;
    _texelWidth = newValue;
    
    [self setFloat:_texelWidth forUniform:texelWidthUniform program:filterProgram];
}

- (void)setTexelHeight:(CGFloat)newValue;
{
    hasOverriddenImageSizeFactor = YES;
    _texelHeight = newValue;
    
    [self setFloat:_texelHeight forUniform:texelHeightUniform program:filterProgram];
}

- (void)setLowerThreshold:(CGFloat)newValue;
{
    _lowerThreshold = newValue;
    
    [self setFloat:_lowerThreshold forUniform:lowerThresholdUniform program:filterProgram];
}

- (void)setUpperThreshold:(CGFloat)newValue;
{
    _upperThreshold = newValue;

    [self setFloat:_upperThreshold forUniform:upperThresholdUniform program:filterProgram];
}



@end

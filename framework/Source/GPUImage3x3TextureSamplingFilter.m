#import "GPUImage3x3TextureSamplingFilter.h"

// Override vertex shader to remove dependent texture reads 
NSString *const kGPUImageNearbyTexelSamplingVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform highp float texelWidth; 
 uniform highp float texelHeight; 
 
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 void main()
 {
     gl_Position = position;
     
     vec2 widthStep = vec2(texelWidth, 0.0);
     vec2 heightStep = vec2(0.0, texelHeight);
     vec2 widthHeightStep = vec2(texelWidth, texelHeight);
     vec2 widthNegativeHeightStep = vec2(texelWidth, -texelHeight);
     
     textureCoordinate = inputTextureCoordinate.xy;
     leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
     rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;
     
     topTextureCoordinate = inputTextureCoordinate.xy - heightStep;
     topLeftTextureCoordinate = inputTextureCoordinate.xy - widthHeightStep;
     topRightTextureCoordinate = inputTextureCoordinate.xy + widthNegativeHeightStep;
     
     bottomTextureCoordinate = inputTextureCoordinate.xy + heightStep;
     bottomLeftTextureCoordinate = inputTextureCoordinate.xy - widthNegativeHeightStep;
     bottomRightTextureCoordinate = inputTextureCoordinate.xy + widthHeightStep;
 }
);


@implementation GPUImage3x3TextureSamplingFilter

@synthesize texelWidth = _texelWidth; 
@synthesize texelHeight = _texelHeight; 

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageNearbyTexelSamplingVertexShaderString fragmentShaderFromString:fragmentShaderString]))
    {
        return nil;
    }
    
    texelWidthUniform = [filterProgram uniformIndex:@"texelWidth"];
    texelHeightUniform = [filterProgram uniformIndex:@"texelHeight"];
    
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
            if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
            {
                glUniform1f(texelWidthUniform, _texelHeight);
                glUniform1f(texelHeightUniform, _texelWidth);
            }
            else
            {
                glUniform1f(texelWidthUniform, _texelWidth);
                glUniform1f(texelHeightUniform, _texelHeight);
            }
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

@end

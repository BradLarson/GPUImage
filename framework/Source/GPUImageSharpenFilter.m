#import "GPUImageSharpenFilter.h"

NSString *const kGPUImageSharpenVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform float imageWidthFactor; 
 uniform float imageHeightFactor; 
 uniform float sharpness;
 
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate; 
 varying vec2 topTextureCoordinate;
 varying vec2 bottomTextureCoordinate;
 
 varying float centerMultiplier;
 varying float edgeMultiplier;
 
 void main()
 {
     gl_Position = position;
     
     mediump vec2 widthStep = vec2(imageWidthFactor, 0.0);
     mediump vec2 heightStep = vec2(0.0, imageHeightFactor);
     
     textureCoordinate = inputTextureCoordinate.xy;
     leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
     rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;
     topTextureCoordinate = inputTextureCoordinate.xy + heightStep;     
     bottomTextureCoordinate = inputTextureCoordinate.xy - heightStep;
     
     centerMultiplier = 1.0 + 4.0 * sharpness;
     edgeMultiplier = sharpness;
 }
 );

NSString *const kGPUImageSharpenFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 leftTextureCoordinate;
 varying highp vec2 rightTextureCoordinate; 
 varying highp vec2 topTextureCoordinate;
 varying highp vec2 bottomTextureCoordinate;
 
 varying highp float centerMultiplier;
 varying highp float edgeMultiplier;

 uniform sampler2D inputImageTexture;
 
 void main()
 {
     mediump vec3 textureColor = texture2D(inputImageTexture, textureCoordinate).rgb;
     mediump vec3 leftTextureColor = texture2D(inputImageTexture, leftTextureCoordinate).rgb;
     mediump vec3 rightTextureColor = texture2D(inputImageTexture, rightTextureCoordinate).rgb;
     mediump vec3 topTextureColor = texture2D(inputImageTexture, topTextureCoordinate).rgb;
     mediump vec3 bottomTextureColor = texture2D(inputImageTexture, bottomTextureCoordinate).rgb;

     gl_FragColor = vec4((textureColor * centerMultiplier - (leftTextureColor * edgeMultiplier + rightTextureColor * edgeMultiplier + topTextureColor * edgeMultiplier + bottomTextureColor * edgeMultiplier)), texture2D(inputImageTexture, bottomTextureCoordinate).w);
 }
);

@implementation GPUImageSharpenFilter

@synthesize sharpness = _sharpness;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageSharpenVertexShaderString fragmentShaderFromString:kGPUImageSharpenFragmentShaderString]))
    {
		return nil;
    }
    
    sharpnessUniform = [filterProgram uniformIndex:@"sharpness"];
    self.sharpness = 0.0;
    
    imageWidthFactorUniform = [filterProgram uniformIndex:@"imageWidthFactor"];
    imageHeightFactorUniform = [filterProgram uniformIndex:@"imageHeightFactor"];
    
    return self;
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
        
        if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
        {
            glUniform1f(imageWidthFactorUniform, 1.0 / filterFrameSize.height);
            glUniform1f(imageHeightFactorUniform, 1.0 / filterFrameSize.width);
        }
        else
        {
            glUniform1f(imageWidthFactorUniform, 1.0 / filterFrameSize.width);
            glUniform1f(imageHeightFactorUniform, 1.0 / filterFrameSize.height);
        }
    });
}

#pragma mark -
#pragma mark Accessors

- (void)setSharpness:(CGFloat)newValue;
{
    _sharpness = newValue;
    
    [self setFloat:_sharpness forUniform:sharpnessUniform program:filterProgram];
}

@end


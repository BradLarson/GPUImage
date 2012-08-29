#import "GPUImageColorPackingFilter.h"

NSString *const kGPUImageColorPackingVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform highp float texelWidth; 
 uniform highp float texelHeight; 
 
 varying vec2 upperLeftInputTextureCoordinate;
 varying vec2 upperRightInputTextureCoordinate;
 varying vec2 lowerLeftInputTextureCoordinate;
 varying vec2 lowerRightInputTextureCoordinate;
 
 void main()
 {
     gl_Position = position;
     
     upperLeftInputTextureCoordinate = inputTextureCoordinate.xy + vec2(-texelWidth, -texelHeight);
     upperRightInputTextureCoordinate = inputTextureCoordinate.xy + vec2(texelWidth, -texelHeight);
     lowerLeftInputTextureCoordinate = inputTextureCoordinate.xy + vec2(-texelWidth, texelHeight);
     lowerRightInputTextureCoordinate = inputTextureCoordinate.xy + vec2(texelWidth, texelHeight);
 }
);

NSString *const kGPUImageColorPackingFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
 uniform sampler2D inputImageTexture;
 
 uniform mediump mat3 convolutionMatrix;
 
 varying highp vec2 outputTextureCoordinate;
 
 varying highp vec2 upperLeftInputTextureCoordinate;
 varying highp vec2 upperRightInputTextureCoordinate;
 varying highp vec2 lowerLeftInputTextureCoordinate;
 varying highp vec2 lowerRightInputTextureCoordinate;
 
 void main()
 {
     float upperLeftIntensity = texture2D(inputImageTexture, upperLeftInputTextureCoordinate).r;
     float upperRightIntensity = texture2D(inputImageTexture, upperRightInputTextureCoordinate).r;
     float lowerLeftIntensity = texture2D(inputImageTexture, lowerLeftInputTextureCoordinate).r;
     float lowerRightIntensity = texture2D(inputImageTexture, lowerRightInputTextureCoordinate).r;
     
     gl_FragColor = vec4(upperLeftIntensity, upperRightIntensity, lowerLeftIntensity, lowerRightIntensity);
 }
);                                                                         

@implementation GPUImageColorPackingFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageColorPackingVertexShaderString fragmentShaderFromString:kGPUImageColorPackingFragmentShaderString]))
    {
        return nil;
    }
    
    texelWidthUniform = [filterProgram uniformIndex:@"texelWidth"];
    texelHeightUniform = [filterProgram uniformIndex:@"texelHeight"];
    
    return self;
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    texelWidth = 0.5 / inputTextureSize.width;
    texelHeight = 0.5 / inputTextureSize.height;

    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
        glUniform1f(texelWidthUniform, texelWidth);
        glUniform1f(texelHeightUniform, texelHeight);
    });
}

#pragma mark -
#pragma mark Managing the display FBOs

- (CGSize)sizeOfFBO;
{
    CGSize outputSize = [self maximumOutputSize];
    if ( (CGSizeEqualToSize(outputSize, CGSizeZero)) || (inputTextureSize.width < outputSize.width) )
    {
        CGSize quarterSize;
        quarterSize.width = inputTextureSize.width / 2.0;
        quarterSize.height = inputTextureSize.height / 2.0;
        return quarterSize;
    }
    else
    {
        return outputSize;
    }
}

#pragma mark -
#pragma mark Rendering

- (CGSize)outputFrameSize;
{
    CGSize quarterSize;
    quarterSize.width = inputTextureSize.width / 2.0;
    quarterSize.height = inputTextureSize.height / 2.0;
    return quarterSize;
}

@end

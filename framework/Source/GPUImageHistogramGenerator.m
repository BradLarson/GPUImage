#import "GPUImageHistogramGenerator.h"

NSString *const kGPUImageHistogramGeneratorVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 varying float height;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = vec2(inputTextureCoordinate.x, 0.5);
     height = 1.0 - inputTextureCoordinate.y;
 }
);

NSString *const kGPUImageHistogramGeneratorFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp float height;
 
 uniform sampler2D inputImageTexture;
 uniform lowp vec3 colorForGraph;
 
 void main()
 {
     lowp float redChannel = texture2D(inputImageTexture, textureCoordinate).r;
     lowp float heightTest = step(height, redChannel);
     gl_FragColor = vec4(heightTest * colorForGraph, 1.0);
 }
);


@implementation GPUImageHistogramGenerator

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageHistogramGeneratorVertexShaderString fragmentShaderFromString:kGPUImageHistogramGeneratorFragmentShaderString]))
    {
        return nil;
    }
    
    colorForGraphUniform = [filterProgram uniformIndex:@"colorForGraph"];
    
    [self setColorForGraphRed:1.0 green:1.0 blue:1.0];

    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setColorForGraphRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;
{
    GLfloat colorToReplace[3];
    colorToReplace[0] = redComponent;
    colorToReplace[1] = greenComponent;    
    colorToReplace[2] = blueComponent;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform3fv(colorForGraphUniform, 1, colorToReplace);    
}

@end

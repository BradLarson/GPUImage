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

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageHistogramGeneratorFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp float height;
 
 uniform sampler2D inputImageTexture;
 uniform lowp vec4 backgroundColor;
 
 void main()
 {
     lowp vec3 colorChannels = texture2D(inputImageTexture, textureCoordinate).rgb;
     lowp vec4 heightTest = vec4(step(height, colorChannels), 1.0);
     gl_FragColor = mix(backgroundColor, heightTest, heightTest.r + heightTest.g + heightTest.b);
 }
);
#else
NSString *const kGPUImageHistogramGeneratorFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying float height;
 
 uniform sampler2D inputImageTexture;
 uniform vec4 backgroundColor;
 
 void main()
 {
     vec3 colorChannels = texture2D(inputImageTexture, textureCoordinate).rgb;
     vec4 heightTest = vec4(step(height, colorChannels), 1.0);
     gl_FragColor = mix(backgroundColor, heightTest, heightTest.r + heightTest.g + heightTest.b);
 }
);
#endif

@implementation GPUImageHistogramGenerator

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageHistogramGeneratorVertexShaderString fragmentShaderFromString:kGPUImageHistogramGeneratorFragmentShaderString]))
    {
        return nil;
    }
    
    backgroundColorUniform = [filterProgram uniformIndex:@"backgroundColor"];

    [self setBackgroundColorRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
{
//    GLfloat backgroundColor[4];
//    backgroundColor[0] = redComponent;
//    backgroundColor[1] = greenComponent;    
//    backgroundColor[2] = blueComponent;
//    backgroundColor[3] = alphaComponent;
    GPUVector4 backgroundColor = {redComponent, greenComponent, blueComponent, alphaComponent};
    
    [self setVec4:backgroundColor forUniform:backgroundColorUniform program:filterProgram];
}

@end

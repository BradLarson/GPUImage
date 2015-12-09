#import "GPUImageColourFASTSamplingOperation.h"

NSString *const kGPUImageColourFASTSamplingVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 attribute vec4 inputTextureCoordinate2;
 
 uniform float texelWidth;
 uniform float texelHeight;
 
 varying vec2 textureCoordinate;
 varying vec2 pointATextureCoordinate;
 varying vec2 pointBTextureCoordinate;
 varying vec2 pointCTextureCoordinate;
 varying vec2 pointDTextureCoordinate;
 varying vec2 pointETextureCoordinate;
 varying vec2 pointFTextureCoordinate;
 varying vec2 pointGTextureCoordinate;
 varying vec2 pointHTextureCoordinate;

 void main()
 {
     gl_Position = position;
     
     float tripleTexelWidth = 3.0 * texelWidth;
     float tripleTexelHeight = 3.0 * texelHeight;
     
     textureCoordinate = inputTextureCoordinate.xy;
     
     pointATextureCoordinate = vec2(textureCoordinate.x + tripleTexelWidth, textureCoordinate.y + texelHeight);
     pointBTextureCoordinate = vec2(textureCoordinate.x + texelWidth, textureCoordinate.y + tripleTexelHeight);
     pointCTextureCoordinate = vec2(textureCoordinate.x - texelWidth, textureCoordinate.y + tripleTexelHeight);
     pointDTextureCoordinate = vec2(textureCoordinate.x - tripleTexelWidth, textureCoordinate.y + texelHeight);
     pointETextureCoordinate = vec2(textureCoordinate.x - tripleTexelWidth, textureCoordinate.y - texelHeight);
     pointFTextureCoordinate = vec2(textureCoordinate.x - texelWidth, textureCoordinate.y - tripleTexelHeight);
     pointGTextureCoordinate = vec2(textureCoordinate.x + texelWidth, textureCoordinate.y - tripleTexelHeight);
     pointHTextureCoordinate = vec2(textureCoordinate.x + tripleTexelWidth, textureCoordinate.y - texelHeight);
 }
);

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageColourFASTSamplingFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying vec2 textureCoordinate;
 varying vec2 pointATextureCoordinate;
 varying vec2 pointBTextureCoordinate;
 varying vec2 pointCTextureCoordinate;
 varying vec2 pointDTextureCoordinate;
 varying vec2 pointETextureCoordinate;
 varying vec2 pointFTextureCoordinate;
 varying vec2 pointGTextureCoordinate;
 varying vec2 pointHTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 const float PITwo = 6.2832;
 const float PI = 3.1416;
 void main()
 {
     vec3 centerColor = texture2D(inputImageTexture, textureCoordinate).rgb;
     
     vec3 pointAColor = texture2D(inputImageTexture, pointATextureCoordinate).rgb;
     vec3 pointBColor = texture2D(inputImageTexture, pointBTextureCoordinate).rgb;
     vec3 pointCColor = texture2D(inputImageTexture, pointCTextureCoordinate).rgb;
     vec3 pointDColor = texture2D(inputImageTexture, pointDTextureCoordinate).rgb;
     vec3 pointEColor = texture2D(inputImageTexture, pointETextureCoordinate).rgb;
     vec3 pointFColor = texture2D(inputImageTexture, pointFTextureCoordinate).rgb;
     vec3 pointGColor = texture2D(inputImageTexture, pointGTextureCoordinate).rgb;
     vec3 pointHColor = texture2D(inputImageTexture, pointHTextureCoordinate).rgb;

     vec3 colorComparison = ((pointAColor + pointBColor + pointCColor + pointDColor + pointEColor + pointFColor + pointGColor + pointHColor) * 0.125) - centerColor;

     // Direction calculation drawn from Appendix B of Seth Hall's Ph.D. thesis
     
     vec3 dirX = (pointAColor*0.94868) + (pointBColor*0.316227) - (pointCColor*0.316227) - (pointDColor*0.94868) - (pointEColor*0.94868) - (pointFColor*0.316227) + (pointGColor*0.316227) + (pointHColor*0.94868);
     vec3 dirY = (pointAColor*0.316227) + (pointBColor*0.94868) + (pointCColor*0.94868) + (pointDColor*0.316227) - (pointEColor*0.316227) - (pointFColor*0.94868) - (pointGColor*0.94868) - (pointHColor*0.316227);
     vec3 absoluteDifference = abs(colorComparison);
     float componentLength = length(colorComparison);
     float avgX = dot(absoluteDifference, dirX) / componentLength;
     float avgY = dot(absoluteDifference, dirY) / componentLength;
     float angle = atan(avgY, avgX);
     
     vec3 normalizedColorComparison = (colorComparison + 1.0) * 0.5;
     
     gl_FragColor = vec4(normalizedColorComparison, (angle+PI)/PITwo);
 }
);
#else
NSString *const kGPUImageColourFASTSamplingFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 pointATextureCoordinate;
 varying vec2 pointBTextureCoordinate;
 varying vec2 pointCTextureCoordinate;
 varying vec2 pointDTextureCoordinate;
 varying vec2 pointETextureCoordinate;
 varying vec2 pointFTextureCoordinate;
 varying vec2 pointGTextureCoordinate;
 varying vec2 pointHTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 const float PITwo = 6.2832;
 const float PI = 3.1416;
 void main()
 {
     vec3 centerColor = texture2D(inputImageTexture, textureCoordinate).rgb;
     
     vec3 pointAColor = texture2D(inputImageTexture, pointATextureCoordinate).rgb;
     vec3 pointBColor = texture2D(inputImageTexture, pointBTextureCoordinate).rgb;
     vec3 pointCColor = texture2D(inputImageTexture, pointCTextureCoordinate).rgb;
     vec3 pointDColor = texture2D(inputImageTexture, pointDTextureCoordinate).rgb;
     vec3 pointEColor = texture2D(inputImageTexture, pointETextureCoordinate).rgb;
     vec3 pointFColor = texture2D(inputImageTexture, pointFTextureCoordinate).rgb;
     vec3 pointGColor = texture2D(inputImageTexture, pointGTextureCoordinate).rgb;
     vec3 pointHColor = texture2D(inputImageTexture, pointHTextureCoordinate).rgb;
     
     vec3 colorComparison = ((pointAColor + pointBColor + pointCColor + pointDColor + pointEColor + pointFColor + pointGColor + pointHColor) * 0.125) - centerColor;
     
     // Direction calculation drawn from Appendix B of Seth Hall's Ph.D. thesis
     
     vec3 dirX = (pointAColor*0.94868) + (pointBColor*0.316227) - (pointCColor*0.316227) - (pointDColor*0.94868) - (pointEColor*0.94868) - (pointFColor*0.316227) + (pointGColor*0.316227) + (pointHColor*0.94868);
     vec3 dirY = (pointAColor*0.316227) + (pointBColor*0.94868) + (pointCColor*0.94868) + (pointDColor*0.316227) - (pointEColor*0.316227) - (pointFColor*0.94868) - (pointGColor*0.94868) - (pointHColor*0.316227);
     vec3 absoluteDifference = abs(colorComparison);
     float componentLength = length(colorComparison);
     float avgX = dot(absoluteDifference, dirX) / componentLength;
     float avgY = dot(absoluteDifference, dirY) / componentLength;
     float angle = atan(avgY, avgX);
     
     vec3 normalizedColorComparison = (colorComparison + 1.0) * 0.5;
     
     gl_FragColor = vec4(normalizedColorComparison, (angle+PI)/PITwo);
 }
);
#endif


@implementation GPUImageColourFASTSamplingOperation

@synthesize texelWidth = _texelWidth;
@synthesize texelHeight = _texelHeight;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageColourFASTSamplingVertexShaderString fragmentShaderFromString:kGPUImageColourFASTSamplingFragmentShaderString]))
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
            [GPUImageContext setActiveShaderProgram:filterProgram];
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
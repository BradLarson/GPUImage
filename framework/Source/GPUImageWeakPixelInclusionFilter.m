#import "GPUImageWeakPixelInclusionFilter.h"

@implementation GPUImageWeakPixelInclusionFilter

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageWeakPixelInclusionFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform vec4 fillColor;
 uniform vec4 pixelColor;
 
 void main()
 {
     float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
     float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
     float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
     float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
     float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
     float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
     float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
     float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
     float centerIntensity = texture2D(inputImageTexture, textureCoordinate).r;
     
     float pixelIntensitySum = bottomLeftIntensity + topRightIntensity + topLeftIntensity + bottomRightIntensity + leftIntensity + rightIntensity + bottomIntensity + topIntensity + centerIntensity;
     float sumTest = step(1.5, pixelIntensitySum);
     float pixelTest = step(0.01, centerIntensity);
     
     // JA - Added user definable colors
     if( sumTest * pixelTest > 0.0 )
         gl_FragColor = pixelColor;
     else
         gl_FragColor = fillColor;
     
     //gl_FragColor = vec4(vec3(sumTest * pixelTest), 1.0);
 }
);
#else
NSString *const kGPUImageWeakPixelInclusionFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform vec4 fillColor;
 uniform vec4 pixelColor;
 
 void main()
 {
     float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
     float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
     float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
     float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
     float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
     float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
     float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
     float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
     float centerIntensity = texture2D(inputImageTexture, textureCoordinate).r;
     
     float pixelIntensitySum = bottomLeftIntensity + topRightIntensity + topLeftIntensity + bottomRightIntensity + leftIntensity + rightIntensity + bottomIntensity + topIntensity + centerIntensity;
     float sumTest = step(1.5, pixelIntensitySum);
     float pixelTest = step(0.01, centerIntensity);
     
     // JA - Added user definable colors
     if( sumTest * pixelTest > 0.0 )
         gl_FragColor = pixelColor;
     else
         gl_FragColor = fillColor;
     
     //gl_FragColor = vec4(vec3(sumTest * pixelTest), 1.0);
 }
);
#endif

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kGPUImageWeakPixelInclusionFragmentShaderString]))
    {
		return nil;
    }
    
    fillColorUniform = [filterProgram uniformIndex:@"fillColor"];
    pixelColorUniform = [filterProgram uniformIndex:@"pixelColor"];
    
    [self setFillColor:(GPUVector4){0.0, 0.0, 0.0, 1.0}];
    [self setPixelColor:(GPUVector4){1.0, 1.0, 1.0, 1.0}];
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setFillColor:(GPUVector4)fillColor
{
	_fillColor = fillColor;
	[self setVec4:fillColor forUniform:fillColorUniform program:filterProgram];
}

-(void)setPixelColor:(GPUVector4)pixelColor
{
    _pixelColor = pixelColor;
    [self setVec4:pixelColor forUniform:pixelColorUniform program:filterProgram];
}
@end

#import "GPUImageColorMatrixFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageColorMatrixFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform lowp mat4 colorMatrix;
 uniform lowp float intensity;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     lowp vec4 outputColor = textureColor * colorMatrix;
     
     gl_FragColor = (intensity * outputColor) + ((1.0 - intensity) * textureColor);
 }
);
#else
NSString *const kGPUImageColorMatrixFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform mat4 colorMatrix;
 uniform float intensity;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     vec4 outputColor = textureColor * colorMatrix;
     
     gl_FragColor = (intensity * outputColor) + ((1.0 - intensity) * textureColor);
 }
);
#endif

@implementation GPUImageColorMatrixFilter

@synthesize intensity = _intensity;
@synthesize colorMatrix = _colorMatrix;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageColorMatrixFragmentShaderString]))
    {
        return nil;
    }
    
    colorMatrixUniform = [filterProgram uniformIndex:@"colorMatrix"];
    intensityUniform = [filterProgram uniformIndex:@"intensity"];
    
    self.intensity = 1.f;
    self.colorMatrix = (GPUMatrix4x4){
        {1.f, 0.f, 0.f, 0.f},
        {0.f, 1.f, 0.f, 0.f},
        {0.f, 0.f, 1.f, 0.f},
        {0.f, 0.f, 0.f, 1.f}
    };
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setIntensity:(CGFloat)newIntensity;
{
    _intensity = newIntensity;
    
    [self setFloat:_intensity forUniform:intensityUniform program:filterProgram];
}

- (void)setColorMatrix:(GPUMatrix4x4)newColorMatrix;
{
    _colorMatrix = newColorMatrix;
    
    [self setMatrix4f:_colorMatrix forUniform:colorMatrixUniform program:filterProgram];
}

@end

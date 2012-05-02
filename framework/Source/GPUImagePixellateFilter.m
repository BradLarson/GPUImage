#import "GPUImagePixellateFilter.h"

NSString *const kGPUImagePixellationFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp float fractionalWidthOfPixel;
 
 void main()
 {
     highp vec2 sampleDivisor = vec2(fractionalWidthOfPixel);
     
     highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor);
     gl_FragColor = texture2D(inputImageTexture, samplePos );
 }
 );

@implementation GPUImagePixellateFilter

@synthesize fractionalWidthOfAPixel = _fractionalWidthOfAPixel;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImagePixellationFragmentShaderString]))
    {
		return nil;
    }
    
    fractionalWidthOfAPixelUniform = [filterProgram uniformIndex:@"fractionalWidthOfPixel"];

    self.fractionalWidthOfAPixel = 0.05;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setFractionalWidthOfAPixel:(CGFloat)newValue;
{
    CGFloat singlePixelSpacing;
    if (inputTextureSize.width != 0.0)
    {
        singlePixelSpacing = 1.0 / inputTextureSize.width;
    }
    else
    {
        singlePixelSpacing = 1.0 / 2048.0;
    }
    
    if (newValue < singlePixelSpacing)
    {
        _fractionalWidthOfAPixel = singlePixelSpacing;
    }
    else
    {
        _fractionalWidthOfAPixel = newValue;
    }
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(fractionalWidthOfAPixelUniform, _fractionalWidthOfAPixel);
}

@end

#import "GPUImagePixellateFilter.h"

/* Pixellation fragment shader:
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp fractionalWidthOfPixel;
 
 void main()
 {
    highp vec2 sampleDivisor = vec2(fractionalWidthOfPixel);

    highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor);
    gl_FragColor = texture2D(inputImageTexture, samplePos );
 }
 */

NSString *const kGPUImagePixellationFragmentShaderString = 
@" varying highp vec2 textureCoordinate;\
\
uniform sampler2D inputImageTexture;\
\
uniform highp float fractionalWidthOfPixel;\
\
void main()\
{\
    highp vec2 sampleDivisor = vec2(fractionalWidthOfPixel);\
    \
    highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor);\
    gl_FragColor = texture2D(inputImageTexture, samplePos );\
}";

@implementation GPUImagePixellateFilter

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

@synthesize fractionalWidthOfAPixel;

- (void)setFractionalWidthOfAPixel:(CGFloat)newValue;
{
    fractionalWidthOfAPixel = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(fractionalWidthOfAPixel, fractionalWidthOfAPixel);
}

@end

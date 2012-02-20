#import "GPUImageDissolveBlendFilter.h"

/* Dissolve blending fragment shader:

varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;
uniform lowp float mixturePercent;

void main()
{
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
     
    gl_FragColor = mix(textureColor, textureColor2, mixturePercent);
}
*/



NSString *const kGPUImageDissolveBlendFragmentShaderString = 
@"varying highp vec2 textureCoordinate;\
\
uniform sampler2D inputImageTexture;\
uniform sampler2D inputImageTexture2;\
uniform lowp float mixturePercent;\
\
void main()\
{\
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);\
    lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);\
    \
    gl_FragColor = mix(textureColor, textureColor2, mixturePercent);\
}";

@implementation GPUImageDissolveBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageDissolveBlendFragmentShaderString]))
    {
		return nil;
    }
    
    mixUniform = [filterProgram uniformIndex:@"mixturePercent"];
    self.mix = 0.5;

    return self;
}

#pragma mark -
#pragma mark Accessors

@synthesize mix = _mix;

- (void)setMix:(CGFloat)newValue;
{
    _mix = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(mixUniform, _mix);
}

@end


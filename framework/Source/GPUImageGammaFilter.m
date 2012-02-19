#import "GPUImageGammaFilter.h"

/* Contrast fragment shader:
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float gamma;
 
 void main()
 {
    lowp vec3 textureColor = texture2D(inputImageTexture, textureCoordinate).rgb;
 
    gl_FragColor = vec4(pow(textureColor, gamma), 1.0);
 }
 */


NSString *const kGPUImageGammaFragmentShaderString = 
@"varying highp vec2 textureCoordinate;\
\
uniform sampler2D inputImageTexture;\
uniform lowp float gamma;\
\
void main()\
{\
lowp vec3 textureColor = texture2D(inputImageTexture, textureCoordinate).rgb;\
\
gl_FragColor = vec4(pow(textureColor, vec3(gamma)), 1.0);\
}";


//gl_FragColor = vec4(pow(textureColor, vec3(gamma))), 1.0);\

@implementation GPUImageGammaFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageGammaFragmentShaderString]))
    {
		return nil;
    }
    
    gammaUniform = [filterProgram uniformIndex:@"gamma"];
    self.gamma = 1.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

@synthesize gamma = _gamma;

- (void)setGamma:(CGFloat)newValue;
{
    _gamma = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(gammaUniform, _gamma);
}

@end


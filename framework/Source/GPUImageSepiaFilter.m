#import "GPUImageSepiaFilter.h"

/* Sepia tone fragment shader:

varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform lowp float intensity;

void main()
{
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 outputColor;
    outputColor.r = (textureColor.r * 0.393) + (textureColor.g * 0.769) + (textureColor.b * 0.189);
    outputColor.g = (textureColor.r * 0.349) + (textureColor.g * 0.686) + (textureColor.b * 0.168);    
    outputColor.b = (textureColor.r * 0.272) + (textureColor.g * 0.534) + (textureColor.b * 0.131);
    
    gl_FragColor = (intensity * outputColor) + ((1.0 - intensity) * textureColor);
}
*/



NSString *const kGPUImageSepiaFragmentShaderString = 
@"varying highp vec2 textureCoordinate;\
\
uniform sampler2D inputImageTexture;\
uniform highp float intensity;\
\
void main()\
{\
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);\
    lowp float grey = dot(textureColor.rgb, vec3(0.299, 0.587, 0.114));\
    lowp vec4 outputColor = vec4(grey * vec3(1.2, 1.0, 0.8), 1.0);\
    \
    gl_FragColor = (intensity * outputColor) + ((1.0 - intensity) * textureColor);\
}";

/*
@"varying highp vec2 textureCoordinate;\
\
uniform sampler2D inputImageTexture;\
uniform highp float intensity;\
\
void main()\
{\
lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);\
lowp vec4 outputColor;\
outputColor.r = (textureColor.r * 0.35) + (textureColor.g * 0.7) + (textureColor.b * 0.135);\
outputColor.g = (textureColor.r * 0.349) + (textureColor.g * 0.43) + (textureColor.b * 0.09);\
outputColor.b = (textureColor.r * 0.25) + (textureColor.g * 0.09) + (textureColor.b * 0.01);\
\
gl_FragColor = (intensity * outputColor) + ((1.0 - intensity) * textureColor);\
}";
*/

@implementation GPUImageSepiaFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSepiaFragmentShaderString]))
    {
		return nil;
    }
    
    intensityUniform = [filterProgram uniformIndex:@"intensity"];
    self.intensity = 1.0;

    return self;
}

#pragma mark -
#pragma mark Accessors

@synthesize intensity = _intensity;

- (void)setIntensity:(CGFloat)newValue;
{
    _intensity = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(intensityUniform, _intensity);
}

@end


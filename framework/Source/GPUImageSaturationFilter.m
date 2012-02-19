#import "GPUImageSaturationFilter.h"

/* Saturation fragment shader:

varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform lowp float saturation;

const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721); // Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
 
void main()
{
    lowp vec3 textureColor = texture2D(inputImageTexture, textureCoordinate).rgb;
    lowp float luminance = dot(textureColor, luminanceWeighting);
    lowp vec3 greyScaleColor = vec3(luminance);
     
    gl_FragColor = vec4(mix(greyScaleColor, textureColor, saturation), 1.0);
}
*/



NSString *const kGPUImageSaturationFragmentShaderString = 
@"varying highp vec2 textureCoordinate;\
\
uniform sampler2D inputImageTexture;\
uniform lowp float saturation;\
\
const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);\
\
void main()\
{\
    lowp vec3 textureColor = texture2D(inputImageTexture, textureCoordinate).rgb;\
    lowp float luminance = dot(textureColor, luminanceWeighting);\
    lowp vec3 greyScaleColor = vec3(luminance);\
    \
    gl_FragColor = vec4(mix(greyScaleColor, textureColor, saturation), 1.0);\
}";

@implementation GPUImageSaturationFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSaturationFragmentShaderString]))
    {
		return nil;
    }
    
    saturationUniform = [filterProgram uniformIndex:@"saturation"];
    self.saturation = 1.0;

    return self;
}

#pragma mark -
#pragma mark Accessors

@synthesize saturation = _saturation;

- (void)setSaturation:(CGFloat)newValue;
{
    _saturation = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(saturationUniform, _saturation);
}

@end


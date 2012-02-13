#import "GPUImageSepiaFilter.h"

/* Sepia tone fragment shader:

varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 outputColor;
    outputColor.r = (textureColor.r * 0.393) + (textureColor.g * 0.769) + (textureColor.b * 0.189);
    outputColor.g = (textureColor.r * 0.349) + (textureColor.g * 0.686) + (textureColor.b * 0.168);    
    outputColor.b = (textureColor.r * 0.272) + (textureColor.g * 0.534) + (textureColor.b * 0.131);
    
	gl_FragColor = outputColor;
}
*/

NSString *const kGPUImageSepiaFragmentShaderString = 
@"varying highp vec2 textureCoordinate;\
\
uniform sampler2D inputImageTexture;\
\
void main()\
{\
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);\
    lowp vec4 outputColor;\
    outputColor.r = (textureColor.r * 0.393) + (textureColor.g * 0.769) + (textureColor.b * 0.189);\
    outputColor.g = (textureColor.r * 0.349) + (textureColor.g * 0.686) + (textureColor.b * 0.168);\
    outputColor.b = (textureColor.r * 0.272) + (textureColor.g * 0.534) + (textureColor.b * 0.131);\
    \
	gl_FragColor = outputColor;\
}";

@implementation GPUImageSepiaFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSepiaFragmentShaderString]))
    {
		return nil;
    }

    return self;
}

@end


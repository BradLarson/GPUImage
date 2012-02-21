#import "GPUImageDarkenBlendFilter.h"

/* Darken blending fragment shader:

varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
     
    gl_FragColor = min(textureColor, textureColor2);
}
*/

NSString *const kGPUImageDarkenBlendFragmentShaderString = 
@"varying highp vec2 textureCoordinate;\
\
uniform sampler2D inputImageTexture;\
uniform sampler2D inputImageTexture2;\
\
void main()\
{\
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);\
    lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);\
    \
    gl_FragColor = min(textureColor, textureColor2);\
}";

@implementation GPUImageDarkenBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageDarkenBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


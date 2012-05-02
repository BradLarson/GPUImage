#import "GPUImageHardLightBlendFilter.h"

NSString *const kGPUImageHardLightBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;

 const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

 void main()
 {
     mediump vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
     mediump float luminance = dot(textureColor.rgb, W);

     mediump vec4 whiteColor = vec4(1.0);
     
     mediump vec4 result;
     if (luminance < 0.45)
     {
         result = 2.0 * textureColor * textureColor2;
     }
     else if (luminance > 0.55)
     {
         result = whiteColor - 2.0 * (whiteColor - textureColor2) * (whiteColor - textureColor);
     }
     else
     {
         mediump vec4 result1 = 2.0 * textureColor * textureColor2;
         mediump vec4 result2 = whiteColor - 2.0 * (whiteColor - textureColor2) * (whiteColor - textureColor);
         result = mix(result1, result2, (luminance - 0.45) * 10.0);
     }
     
     gl_FragColor = result;
 }
);


@implementation GPUImageHardLightBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageHardLightBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


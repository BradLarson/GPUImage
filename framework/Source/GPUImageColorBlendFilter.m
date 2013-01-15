#import "GPUImageColorBlendFilter.h"

/**
 * Color blend mode based upon pseudo code from the PDF specification.
 */
NSString *const kGPUImageColorBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 highp float lum(lowp vec3 c) {
     return dot(c, vec3(0.3, 0.59, 0.11));
 }
 
 lowp vec3 clipcolor(lowp vec3 c) {
     highp float l = lum(c);
     lowp float n = min(min(c.r, c.g), c.b);
     lowp float x = max(max(c.r, c.g), c.b);
     
     if (n < 0.0) {
         c.r = l + ((c.r - l) * l) / (l - n);
         c.g = l + ((c.g - l) * l) / (l - n);
         c.b = l + ((c.b - l) * l) / (l - n);
     }
     if (x > 1.0) {
         c.r = l + ((c.r - l) * (1.0 - l)) / (x - l);
         c.g = l + ((c.g - l) * (1.0 - l)) / (x - l);
         c.b = l + ((c.b - l) * (1.0 - l)) / (x - l);
     }
     
     return c;
 }

 lowp vec3 setlum(lowp vec3 c, highp float l) {
     highp float d = l - lum(c);
     c = c + vec3(d);
     return clipcolor(c);
 }
 
 void main()
 {
	 highp vec4 baseColor = texture2D(inputImageTexture, textureCoordinate);
	 highp vec4 overlayColor = texture2D(inputImageTexture2, textureCoordinate2);

     gl_FragColor = vec4(baseColor.rgb * (1.0 - overlayColor.a) + setlum(overlayColor.rgb, lum(baseColor.rgb)) * overlayColor.a, baseColor.a);
 }
 );


@implementation GPUImageColorBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageColorBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end
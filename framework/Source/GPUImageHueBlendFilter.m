#import "GPUImageHueBlendFilter.h"

/**
 * Hue blend mode based upon pseudo code from the PDF specification.
 */
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageHueBlendFragmentShaderString = SHADER_STRING
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
 
 highp float sat(lowp vec3 c) {
     lowp float n = min(min(c.r, c.g), c.b);
     lowp float x = max(max(c.r, c.g), c.b);
     return x - n;
 }
 
 lowp float mid(lowp float cmin, lowp float cmid, lowp float cmax, highp float s) {
     return ((cmid - cmin) * s) / (cmax - cmin);
 }
 
 lowp vec3 setsat(lowp vec3 c, highp float s) {
     if (c.r > c.g) {
         if (c.r > c.b) {
             if (c.g > c.b) {
                 /* g is mid, b is min */
                 c.g = mid(c.b, c.g, c.r, s);
                 c.b = 0.0;
             } else {
                 /* b is mid, g is min */
                 c.b = mid(c.g, c.b, c.r, s);
                 c.g = 0.0;
             }
             c.r = s;
         } else {
             /* b is max, r is mid, g is min */
             c.r = mid(c.g, c.r, c.b, s);
             c.b = s;
             c.r = 0.0;
         }
     } else if (c.r > c.b) {
         /* g is max, r is mid, b is min */
         c.r = mid(c.b, c.r, c.g, s);
         c.g = s;
         c.b = 0.0;
     } else if (c.g > c.b) {
         /* g is max, b is mid, r is min */
         c.b = mid(c.r, c.b, c.g, s);
         c.g = s;
         c.r = 0.0;
     } else if (c.b > c.g) {
         /* b is max, g is mid, r is min */
         c.g = mid(c.r, c.g, c.b, s);
         c.b = s;
         c.r = 0.0;
     } else {
         c = vec3(0.0);
     }
     return c;
 }
 
 void main()
 {
	 highp vec4 baseColor = texture2D(inputImageTexture, textureCoordinate);
	 highp vec4 overlayColor = texture2D(inputImageTexture2, textureCoordinate2);
     
     gl_FragColor = vec4(baseColor.rgb * (1.0 - overlayColor.a) + setlum(setsat(overlayColor.rgb, sat(baseColor.rgb)), lum(baseColor.rgb)) * overlayColor.a, baseColor.a);
 }
);
#else
NSString *const kGPUImageHueBlendFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 float lum(vec3 c) {
     return dot(c, vec3(0.3, 0.59, 0.11));
 }
 
 vec3 clipcolor(vec3 c) {
     float l = lum(c);
     float n = min(min(c.r, c.g), c.b);
     float x = max(max(c.r, c.g), c.b);
     
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
 
 vec3 setlum(vec3 c, float l) {
     float d = l - lum(c);
     c = c + vec3(d);
     return clipcolor(c);
 }
 
 float sat(vec3 c) {
     float n = min(min(c.r, c.g), c.b);
     float x = max(max(c.r, c.g), c.b);
     return x - n;
 }
 
 float mid(float cmin, float cmid, float cmax, float s) {
     return ((cmid - cmin) * s) / (cmax - cmin);
 }
 
 vec3 setsat(vec3 c, float s) {
     if (c.r > c.g) {
         if (c.r > c.b) {
             if (c.g > c.b) {
                 /* g is mid, b is min */
                 c.g = mid(c.b, c.g, c.r, s);
                 c.b = 0.0;
             } else {
                 /* b is mid, g is min */
                 c.b = mid(c.g, c.b, c.r, s);
                 c.g = 0.0;
             }
             c.r = s;
         } else {
             /* b is max, r is mid, g is min */
             c.r = mid(c.g, c.r, c.b, s);
             c.b = s;
             c.r = 0.0;
         }
     } else if (c.r > c.b) {
         /* g is max, r is mid, b is min */
         c.r = mid(c.b, c.r, c.g, s);
         c.g = s;
         c.b = 0.0;
     } else if (c.g > c.b) {
         /* g is max, b is mid, r is min */
         c.b = mid(c.r, c.b, c.g, s);
         c.g = s;
         c.r = 0.0;
     } else if (c.b > c.g) {
         /* b is max, g is mid, r is min */
         c.g = mid(c.r, c.g, c.b, s);
         c.b = s;
         c.r = 0.0;
     } else {
         c = vec3(0.0);
     }
     return c;
 }
 
 void main()
 {
	 vec4 baseColor = texture2D(inputImageTexture, textureCoordinate);
	 vec4 overlayColor = texture2D(inputImageTexture2, textureCoordinate2);
     
     gl_FragColor = vec4(baseColor.rgb * (1.0 - overlayColor.a) + setlum(setsat(overlayColor.rgb, sat(baseColor.rgb)), lum(baseColor.rgb)) * overlayColor.a, baseColor.a);
 }
);
#endif

@implementation GPUImageHueBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageHueBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end

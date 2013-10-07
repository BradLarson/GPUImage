//  Created by Jorge Garcia on 9/5/12.

#import "GPUImageNormalBlendFilter.h"
/*
 This equation is a simplification of the general blending equation. It assumes the destination color is opaque, and therefore drops the destination color's alpha term.
 
 D = C1 * C1a + C2 * C2a * (1 - C1a)
 where D is the resultant color, C1 is the color of the first element, C1a is the alpha of the first element, C2 is the second element color, C2a is the alpha of the second element. The destination alpha is calculated with:
 
 Da = C1a + C2a * (1 - C1a)
 The resultant color is premultiplied with the alpha. To restore the color to the unmultiplied values, just divide by Da, the resultant alpha.
 
 http://stackoverflow.com/questions/1724946/blend-mode-on-a-transparent-and-semi-transparent-background
 
 For some reason Photoshop behaves 
 D = C1 + C2 * C2a * (1 - C1a)
 */
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageNormalBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     lowp vec4 c2 = texture2D(inputImageTexture, textureCoordinate);
	 lowp vec4 c1 = texture2D(inputImageTexture2, textureCoordinate2);
     
     lowp vec4 outputColor;
     
//     outputColor.r = c1.r + c2.r * c2.a * (1.0 - c1.a);
//     outputColor.g = c1.g + c2.g * c2.a * (1.0 - c1.a);
//     outputColor.b = c1.b + c2.b * c2.a * (1.0 - c1.a);
//     outputColor.a = c1.a + c2.a * (1.0 - c1.a);
     
     lowp float a = c1.a + c2.a * (1.0 - c1.a);
     lowp float alphaDivisor = a + step(a, 0.0); // Protect against a divide-by-zero blacking out things in the output

     outputColor.r = (c1.r * c1.a + c2.r * c2.a * (1.0 - c1.a))/alphaDivisor;
     outputColor.g = (c1.g * c1.a + c2.g * c2.a * (1.0 - c1.a))/alphaDivisor;
     outputColor.b = (c1.b * c1.a + c2.b * c2.a * (1.0 - c1.a))/alphaDivisor;
     outputColor.a = a;

     gl_FragColor = outputColor;
 }
);
#else
NSString *const kGPUImageNormalBlendFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 c2 = texture2D(inputImageTexture, textureCoordinate);
	 vec4 c1 = texture2D(inputImageTexture2, textureCoordinate2);
     
     vec4 outputColor;
     
     //     outputColor.r = c1.r + c2.r * c2.a * (1.0 - c1.a);
     //     outputColor.g = c1.g + c2.g * c2.a * (1.0 - c1.a);
     //     outputColor.b = c1.b + c2.b * c2.a * (1.0 - c1.a);
     //     outputColor.a = c1.a + c2.a * (1.0 - c1.a);
     
     float a = c1.a + c2.a * (1.0 - c1.a);
     float alphaDivisor = a + step(a, 0.0); // Protect against a divide-by-zero blacking out things in the output

     outputColor.r = (c1.r * c1.a + c2.r * c2.a * (1.0 - c1.a))/alphaDivisor;
     outputColor.g = (c1.g * c1.a + c2.g * c2.a * (1.0 - c1.a))/alphaDivisor;
     outputColor.b = (c1.b * c1.a + c2.b * c2.a * (1.0 - c1.a))/alphaDivisor;
     outputColor.a = a;
     
     gl_FragColor = outputColor;
 }
);
#endif

@implementation GPUImageNormalBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageNormalBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end
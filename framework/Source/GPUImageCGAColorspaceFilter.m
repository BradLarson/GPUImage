//
//  GPUImageCGAColorspaceFilter.m
//

#import "GPUImageCGAColorspaceFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageCGAColorspaceFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     highp vec2 sampleDivisor = vec2(1.0 / 200.0, 1.0 / 320.0);
     //highp vec4 colorDivisor = vec4(colorDepth);
     
     highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor);
     highp vec4 color = texture2D(inputImageTexture, samplePos );
     
     //gl_FragColor = texture2D(inputImageTexture, samplePos );
     mediump vec4 colorCyan = vec4(85.0 / 255.0, 1.0, 1.0, 1.0);
     mediump vec4 colorMagenta = vec4(1.0, 85.0 / 255.0, 1.0, 1.0);
     mediump vec4 colorWhite = vec4(1.0, 1.0, 1.0, 1.0);
     mediump vec4 colorBlack = vec4(0.0, 0.0, 0.0, 1.0);
     
     mediump vec4 endColor;
     highp float blackDistance = distance(color, colorBlack);
     highp float whiteDistance = distance(color, colorWhite);
     highp float magentaDistance = distance(color, colorMagenta);
     highp float cyanDistance = distance(color, colorCyan);
     
     mediump vec4 finalColor;
     
     highp float colorDistance = min(magentaDistance, cyanDistance);
     colorDistance = min(colorDistance, whiteDistance);
     colorDistance = min(colorDistance, blackDistance); 
     
     if (colorDistance == blackDistance) {
         finalColor = colorBlack;
     } else if (colorDistance == whiteDistance) {
         finalColor = colorWhite;
     } else if (colorDistance == cyanDistance) {
         finalColor = colorCyan;
     } else {
         finalColor = colorMagenta;
     }
     
     gl_FragColor = finalColor;
 }
);
#else
NSString *const kGPUImageCGAColorspaceFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     vec2 sampleDivisor = vec2(1.0 / 200.0, 1.0 / 320.0);
     //highp vec4 colorDivisor = vec4(colorDepth);
     
     vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor);
     vec4 color = texture2D(inputImageTexture, samplePos );
     
     //gl_FragColor = texture2D(inputImageTexture, samplePos );
     vec4 colorCyan = vec4(85.0 / 255.0, 1.0, 1.0, 1.0);
     vec4 colorMagenta = vec4(1.0, 85.0 / 255.0, 1.0, 1.0);
     vec4 colorWhite = vec4(1.0, 1.0, 1.0, 1.0);
     vec4 colorBlack = vec4(0.0, 0.0, 0.0, 1.0);
     
     vec4 endColor;
     float blackDistance = distance(color, colorBlack);
     float whiteDistance = distance(color, colorWhite);
     float magentaDistance = distance(color, colorMagenta);
     float cyanDistance = distance(color, colorCyan);
     
     vec4 finalColor;
     
     float colorDistance = min(magentaDistance, cyanDistance);
     colorDistance = min(colorDistance, whiteDistance);
     colorDistance = min(colorDistance, blackDistance);
     
     if (colorDistance == blackDistance) {
         finalColor = colorBlack;
     } else if (colorDistance == whiteDistance) {
         finalColor = colorWhite;
     } else if (colorDistance == cyanDistance) {
         finalColor = colorCyan;
     } else {
         finalColor = colorMagenta;
     }
     
     gl_FragColor = finalColor;
 }
);
#endif

@implementation GPUImageCGAColorspaceFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageCGAColorspaceFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end

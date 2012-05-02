#import "GPUImageCrosshatchFilter.h"

// Shader code based on http://machinesdontcare.wordpress.com/

NSString *const kGPUImageCrosshatchFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
    mediump float lum = length(texture2D(inputImageTexture, textureCoordinate).rgb);
	
	gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
	
     mediump vec4 color = texture2D(inputImageTexture, textureCoordinate);
     
	if (lum < 1.00) {
		if (mod(gl_FragCoord.x + gl_FragCoord.y, 10.0) == 0.0) {
			gl_FragColor = color;
		}
	}
	
	if (lum < 0.75) {
		if (mod(gl_FragCoord.x - gl_FragCoord.y, 10.0) == 0.0) {
			gl_FragColor = color;
		}
	}
	
	if (lum < 0.50) {
		if (mod(gl_FragCoord.x + gl_FragCoord.y - 5.0, 10.0) == 0.0) {
			gl_FragColor = color;
		}
	}
	
	if (lum < 0.3) {
		if (mod(gl_FragCoord.x - gl_FragCoord.y - 5.0, 10.0) == 0.0) {
			gl_FragColor = color;
		}
	}
 }
 );


@implementation GPUImageCrosshatchFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageCrosshatchFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end

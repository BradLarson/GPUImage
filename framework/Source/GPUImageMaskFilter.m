#import "GPUImageMaskFilter.h"

NSString *const kGPUImageMaskShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
	 lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
	 lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
	 
	 //Averages mask's the RGB values, and scales that value by the mask's alpha
	 //
	 //The dot product should take fewer cycles than doing an average normally
	 //
	 //Typical/ideal case, R,G, and B will be the same, and Alpha will be 1.0
	 lowp float newAlpha = dot(textureColor2.rgb, vec3(.33333334, .33333334, .33333334)) * textureColor2.a;
	 	 
	 gl_FragColor = vec4(textureColor.xyz, newAlpha);
//	 gl_FragColor = vec4(textureColor2);
 }
 );

@implementation GPUImageMaskFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageMaskShaderString]))
    {
		return nil;
    }
    
    return self;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates sourceTexture:sourceTexture];
    glDisable(GL_BLEND);
}

@end


#import "GPUImageColorInvertFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageInvertFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4((1.0 - textureColor.rgb), textureColor.w);
 }
);                                                                    
#else
NSString *const kGPUImageInvertFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4((1.0 - textureColor.rgb), textureColor.w);
 }
 );
#endif

@implementation GPUImageColorInvertFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageInvertFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


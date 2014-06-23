#import "GPUImageOpacityFilter.h"

@implementation GPUImageOpacityFilter

@synthesize opacity = _opacity;

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageOpacityFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float opacity;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(textureColor.rgb, textureColor.a * opacity);
 }
);
#else
NSString *const kGPUImageOpacityFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float opacity;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(textureColor.rgb, textureColor.a * opacity);
 }
);
#endif

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageOpacityFragmentShaderString]))
    {
		return nil;
    }
    
    opacityUniform = [filterProgram uniformIndex:@"opacity"];
    self.opacity = 1.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setOpacity:(CGFloat)newValue;
{
    _opacity = newValue;
    
    [self setFloat:_opacity forUniform:opacityUniform program:filterProgram];
}

@end

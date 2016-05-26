#import "GPUImageColorInvertFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageInvertFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;

 uniform sampler2D inputImageTexture;
 uniform lowp float invert;

 void main()
 {
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);

    gl_FragColor = vec4(textureColor.rgb - ((2.0 * textureColor.rgb - 1.0) * vec3(invert)), textureColor.w);
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

     gl_FragColor = vec4(textureColor.rgb - ((2.0 * textureColor.rgb - 1.0) * vec3(invert)), textureColor.w);
 }
 );
#endif

@implementation GPUImageColorInvertFilter

@synthesize invert = _invert;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageInvertFragmentShaderString]))
    {
		return nil;
    }

    invertUniform = [filterProgram uniformIndex:@"invert"];
    self.invert = 1.0;

    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setInvert:(CGFloat)newValue;
{
    _invert = newValue;

    [self setFloat:_invert forUniform:invertUniform program:filterProgram];
}

@end

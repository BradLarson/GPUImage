#import "GPUImageGammaFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageGammaFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float gamma;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(pow(textureColor.rgb, vec3(gamma)), textureColor.w);
 }
);
#else
NSString *const kGPUImageGammaFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float gamma;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(pow(textureColor.rgb, vec3(gamma)), textureColor.w);
 }
);
#endif

@implementation GPUImageGammaFilter

@synthesize gamma = _gamma;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageGammaFragmentShaderString]))
    {
		return nil;
    }
    
    gammaUniform = [filterProgram uniformIndex:@"gamma"];
    self.gamma = 1.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setGamma:(CGFloat)newValue;
{
    _gamma = newValue;
    
    [self setFloat:_gamma forUniform:gammaUniform program:filterProgram];
}

@end


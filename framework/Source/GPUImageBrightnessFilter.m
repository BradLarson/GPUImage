#import "GPUImageBrightnessFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageBrightnessFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float brightness;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4((textureColor.rgb + vec3(brightness)), textureColor.w);
 }
);
#else
NSString *const kGPUImageBrightnessFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float brightness;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4((textureColor.rgb + vec3(brightness)), textureColor.w);
 }
 );
#endif

@implementation GPUImageBrightnessFilter

@synthesize brightness = _brightness;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageBrightnessFragmentShaderString]))
    {
		return nil;
    }
    
    brightnessUniform = [filterProgram uniformIndex:@"brightness"];
    self.brightness = 0.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setBrightness:(CGFloat)newValue;
{
    _brightness = newValue;
    
    [self setFloat:_brightness forUniform:brightnessUniform program:filterProgram];
}

@end


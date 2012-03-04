#import "GPUImageBrightnessFilter.h"

NSString *const kGPUImageBrightnessFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float brightness;
 
 void main()
 {
     lowp vec3 textureColor = texture2D(inputImageTexture, textureCoordinate).rgb;
     
     gl_FragColor = vec4((textureColor + vec3(brightness)), 1.0);
 }
);

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
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(brightnessUniform, _brightness);
}

@end


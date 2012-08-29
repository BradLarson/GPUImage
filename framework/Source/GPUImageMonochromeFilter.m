#import "GPUImageMonochromeFilter.h"

NSString *const kGPUMonochromeFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float intensity;
 uniform vec3 filterColor;
 
 const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
	//desat, then apply overlay blend
	lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
	float luminance = dot(textureColor.rgb, luminanceWeighting);
	
	lowp vec4 desat = vec4(vec3(luminance), 1.0);
	
	//overlay
	lowp vec4 outputColor = vec4(
                                 (desat.r < 0.5 ? (2.0 * desat.r * filterColor.r) : (1.0 - 2.0 * (1.0 - desat.r) * (1.0 - filterColor.r))),
                                 (desat.g < 0.5 ? (2.0 * desat.g * filterColor.g) : (1.0 - 2.0 * (1.0 - desat.g) * (1.0 - filterColor.g))),
                                 (desat.b < 0.5 ? (2.0 * desat.b * filterColor.b) : (1.0 - 2.0 * (1.0 - desat.b) * (1.0 - filterColor.b))),
                                 1.0
                                 );
	
	//which is better, or are they equal?
	gl_FragColor = vec4( mix(textureColor.rgb, outputColor.rgb, intensity), textureColor.a);
 }
);

@implementation GPUImageMonochromeFilter

@synthesize intensity = _intensity;
@synthesize color = _color;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUMonochromeFragmentShaderString]))
    {
		return nil;
    }
    
    intensityUniform = [filterProgram uniformIndex:@"intensity"];
    filterColorUniform = [filterProgram uniformIndex:@"filterColor"];
    
    self.intensity = 1.0;
	self.color = (GPUVector4){0.6f, 0.45f, 0.3f, 1.f};
	//self.color = [CIColor colorWithRed:0.6 green:0.45 blue:0.3 alpha:1.];
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setColor:(GPUVector4)color;
{    
	
	_color = color;
	
	[self setColorRed:color.one green:color.two blue:color.three];
}

- (void)setColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;
{
    GPUVector3 filterColor = {redComponent, greenComponent, blueComponent};
    
    [self setVec3:filterColor forUniform:filterColorUniform program:filterProgram];
}

- (void)setIntensity:(CGFloat)newValue;
{
    _intensity = newValue;
    
    [self setFloat:_intensity forUniform:intensityUniform program:filterProgram];
}

@end

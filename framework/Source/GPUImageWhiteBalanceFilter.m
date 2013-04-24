#import "GPUImageWhiteBalanceFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageWhiteBalanceFragmentShaderString = SHADER_STRING
(
uniform sampler2D inputImageTexture;
varying highp vec2 textureCoordinate;
 
uniform lowp float temperature;
uniform lowp float tint;

const lowp vec3 warmFilter = vec3(0.93, 0.54, 0.0);

const mediump mat3 RGBtoYIQ = mat3(0.299, 0.587, 0.114, 0.596, -0.274, -0.322, 0.212, -0.523, 0.311);
const mediump mat3 YIQtoRGB = mat3(1.0, 0.956, 0.621, 1.0, -0.272, -0.647, 1.0, -1.105, 1.702);

void main()
{
	lowp vec4 source = texture2D(inputImageTexture, textureCoordinate);
	
	mediump vec3 yiq = RGBtoYIQ * source.rgb; //adjusting tint
	yiq.b = clamp(yiq.b + tint*0.5226*0.1, -0.5226, 0.5226);
	lowp vec3 rgb = YIQtoRGB * yiq;

	lowp vec3 processed = vec3(
		(rgb.r < 0.5 ? (2.0 * rgb.r * warmFilter.r) : (1.0 - 2.0 * (1.0 - rgb.r) * (1.0 - warmFilter.r))), //adjusting temperature
		(rgb.g < 0.5 ? (2.0 * rgb.g * warmFilter.g) : (1.0 - 2.0 * (1.0 - rgb.g) * (1.0 - warmFilter.g))), 
		(rgb.b < 0.5 ? (2.0 * rgb.b * warmFilter.b) : (1.0 - 2.0 * (1.0 - rgb.b) * (1.0 - warmFilter.b))));

	gl_FragColor = vec4(mix(rgb, processed, temperature), source.a);
}
);
#else
NSString *const kGPUImageWhiteBalanceFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying vec2 textureCoordinate;
 
 uniform float temperature;
 uniform float tint;
 
 const vec3 warmFilter = vec3(0.93, 0.54, 0.0);
 
 const mat3 RGBtoYIQ = mat3(0.299, 0.587, 0.114, 0.596, -0.274, -0.322, 0.212, -0.523, 0.311);
 const mat3 YIQtoRGB = mat3(1.0, 0.956, 0.621, 1.0, -0.272, -0.647, 1.0, -1.105, 1.702);
 
 void main()
{
	vec4 source = texture2D(inputImageTexture, textureCoordinate);
	
	vec3 yiq = RGBtoYIQ * source.rgb; //adjusting tint
	yiq.b = clamp(yiq.b + tint*0.5226*0.1, -0.5226, 0.5226);
	vec3 rgb = YIQtoRGB * yiq;
    
	vec3 processed = vec3(
                               (rgb.r < 0.5 ? (2.0 * rgb.r * warmFilter.r) : (1.0 - 2.0 * (1.0 - rgb.r) * (1.0 - warmFilter.r))), //adjusting temperature
                               (rgb.g < 0.5 ? (2.0 * rgb.g * warmFilter.g) : (1.0 - 2.0 * (1.0 - rgb.g) * (1.0 - warmFilter.g))),
                               (rgb.b < 0.5 ? (2.0 * rgb.b * warmFilter.b) : (1.0 - 2.0 * (1.0 - rgb.b) * (1.0 - warmFilter.b))));
    
	gl_FragColor = vec4(mix(rgb, processed, temperature), source.a);
}
);
#endif

@implementation GPUImageWhiteBalanceFilter

@synthesize temperature = _temperature;
@synthesize tint = _tint;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageWhiteBalanceFragmentShaderString]))
    {
		return nil;
    }
    
    temperatureUniform = [filterProgram uniformIndex:@"temperature"];
	tintUniform = [filterProgram uniformIndex:@"tint"];
	
    self.temperature = 5000.0;
	self.tint = 0.0;

    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setTemperature:(int)newValue;
{
    _temperature = newValue;
    
    [self setFloat:_temperature < 5000 ? 0.0004 * (float)(_temperature-5000.0) : 0.00006 * (float)(_temperature-5000.0) forUniform:temperatureUniform program:filterProgram];
}

- (void)setTint:(int)newValue;
{
	_tint = newValue;
	
	[self setFloat:(float)(_tint) / 100.0 forUniform:tintUniform program:filterProgram];
}

@end


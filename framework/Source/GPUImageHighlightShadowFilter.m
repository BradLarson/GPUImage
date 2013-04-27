#import "GPUImageHighlightShadowFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageHighlightShadowFragmentShaderString = SHADER_STRING
(
uniform sampler2D inputImageTexture;
varying highp vec2 textureCoordinate;
 
uniform lowp float shadows;
uniform lowp float highlights;

const mediump vec3 luminanceWeighting = vec3(0.3, 0.3, 0.3);

void main()
{
	lowp vec4 source = texture2D(inputImageTexture, textureCoordinate);
	mediump float luminance = dot(source.rgb, luminanceWeighting);

	mediump float shadow = clamp((pow(luminance, 1.0/(shadows+1.0)) + (-0.76)*pow(luminance, 2.0/(shadows+1.0))) - luminance, 0.0, 1.0);
	mediump float highlight = clamp((1.0 - (pow(1.0-luminance, 1.0/(2.0-highlights)) + (-0.8)*pow(1.0-luminance, 2.0/(2.0-highlights)))) - luminance, -1.0, 0.0);
	lowp vec3 result = vec3(0.0, 0.0, 0.0) + ((luminance + shadow + highlight) - 0.0) * ((source.rgb - vec3(0.0, 0.0, 0.0))/(luminance - 0.0));

	gl_FragColor = vec4(result.rgb, source.a);
}
);
#else
NSString *const kGPUImageHighlightShadowFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying vec2 textureCoordinate;
 
 uniform float shadows;
 uniform float highlights;
 
 const vec3 luminanceWeighting = vec3(0.3, 0.3, 0.3);
 
 void main()
 {
	vec4 source = texture2D(inputImageTexture, textureCoordinate);
	float luminance = dot(source.rgb, luminanceWeighting);
    
	float shadow = clamp((pow(luminance, 1.0/(shadows+1.0)) + (-0.76)*pow(luminance, 2.0/(shadows+1.0))) - luminance, 0.0, 1.0);
	float highlight = clamp((1.0 - (pow(1.0-luminance, 1.0/(2.0-highlights)) + (-0.8)*pow(1.0-luminance, 2.0/(2.0-highlights)))) - luminance, -1.0, 0.0);
	vec3 result = vec3(0.0, 0.0, 0.0) + ((luminance + shadow + highlight) - 0.0) * ((source.rgb - vec3(0.0, 0.0, 0.0))/(luminance - 0.0));
    
	gl_FragColor = vec4(result.rgb, source.a);
 }
);
#endif

@implementation GPUImageHighlightShadowFilter

@synthesize shadows = _shadows;
@synthesize highlights = _highlights;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageHighlightShadowFragmentShaderString]))
    {
		return nil;
    }
    
    shadowsUniform = [filterProgram uniformIndex:@"shadows"];
	highlightsUniform = [filterProgram uniformIndex:@"highlights"];
	
    self.shadows = 0.0;
	self.highlights = 1.0;

    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setShadows:(CGFloat)newValue;
{
    _shadows = newValue;

    [self setFloat:_shadows forUniform:shadowsUniform program:filterProgram];
}

- (void)setHighlights:(CGFloat)newValue;
{
	_highlights = newValue;

    [self setFloat:_highlights forUniform:highlightsUniform program:filterProgram];
}

@end


#import "GPUImageVignetteFilter.h"

NSString *const kGPUImageVignetteFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying highp vec2 textureCoordinate;
 
 uniform highp float vignetteStart;
 uniform highp float vignetteEnd;
 
 void main()
 {
    lowp vec3 rgb = texture2D(inputImageTexture, textureCoordinate).rgb;
    lowp float d = distance(textureCoordinate, vec2(0.5,0.5));
    rgb *= smoothstep(vignetteEnd, vignetteStart, d);
    gl_FragColor = vec4(vec3(rgb),1.0);
 }
);


@implementation GPUImageVignetteFilter

@synthesize vignetteStart =_vignetteStart;
@synthesize vignetteEnd = _vignetteEnd;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageVignetteFragmentShaderString]))
    {
		return nil;
    }
    
    vignetteStartUniform = [filterProgram uniformIndex:@"vignetteStart"];
    vignetteEndUniform = [filterProgram uniformIndex:@"vignetteEnd"];
    
    self.vignetteStart = 0.3;
    self.vignetteEnd = 0.75;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setVignetteStart:(CGFloat)newValue;
{
    _vignetteStart = newValue;
    
    [self setFloat:_vignetteStart forUniform:vignetteStartUniform program:filterProgram];
}

- (void)setVignetteEnd:(CGFloat)newValue;
{
    _vignetteEnd = newValue;

    [self setFloat:_vignetteEnd forUniform:vignetteEndUniform program:filterProgram];
}

@end

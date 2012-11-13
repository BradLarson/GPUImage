#import "GPUImageVignetteFilter.h"

NSString *const kGPUImageVignetteFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying highp vec2 textureCoordinate;
 
 uniform lowp vec2 vignetteCenter;
 uniform lowp vec3 vignetteColor;
 uniform highp float vignetteStart;
 uniform highp float vignetteEnd;
 
 void main()
 {
     /*
     lowp vec3 rgb = texture2D(inputImageTexture, textureCoordinate).rgb;
     lowp float d = distance(textureCoordinate, vec2(0.5,0.5));
     rgb *= (1.0 - smoothstep(vignetteStart, vignetteEnd, d));
     gl_FragColor = vec4(vec3(rgb),1.0);
      */
     
     lowp vec3 rgb = texture2D(inputImageTexture, textureCoordinate).rgb;
     lowp float d = distance(textureCoordinate, vec2(vignetteCenter.x, vignetteCenter.y));
     lowp float percent = smoothstep(vignetteStart, vignetteEnd, d);
     gl_FragColor = vec4(mix(rgb.x, vignetteColor.x, percent), mix(rgb.y, vignetteColor.y, percent), mix(rgb.z, vignetteColor.z, percent), 1.0);
 }
);

@implementation GPUImageVignetteFilter

@synthesize vignetteCenter = _vignetteCenter;
@synthesize vignetteColor = _vignetteColor;
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
    
    vignetteCenterUniform = [filterProgram uniformIndex:@"vignetteCenter"];
    vignetteColorUniform = [filterProgram uniformIndex:@"vignetteColor"];
    vignetteStartUniform = [filterProgram uniformIndex:@"vignetteStart"];
    vignetteEndUniform = [filterProgram uniformIndex:@"vignetteEnd"];
    
    self.vignetteCenter = (CGPoint){ 0.5f, 0.5f };
    self.vignetteColor = (GPUVector3){ 0.0f, 0.0f, 0.0f };
    self.vignetteStart = 0.3;
    self.vignetteEnd = 0.75;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setVignetteCenter:(CGPoint)newValue
{
    _vignetteCenter = newValue;
    
    [self setPoint:newValue forUniform:vignetteCenterUniform program:filterProgram];
}

- (void)setVignetteColor:(GPUVector3)newValue
{
    _vignetteColor = newValue;
    
    [self setVec3:newValue forUniform:vignetteColorUniform program:filterProgram];
}

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

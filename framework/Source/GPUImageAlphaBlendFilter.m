#import "GPUImageAlphaBlendFilter.h"

NSString *const kGPUImageAlphaBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform lowp float mixturePercent;
 
 void main()
 {
	 lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
	 lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
	 
	 if (textureColor2.a == 0.0) {
		 gl_FragColor = textureColor;
	 } else {
		 gl_FragColor = vec4(mix(textureColor.rgb, textureColor2.rgb / textureColor2.a,
								 mixturePercent * textureColor2.a), textureColor.a);
	 }
 }
 );


@implementation GPUImageAlphaBlendFilter

@synthesize mix = _mix;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageAlphaBlendFragmentShaderString]))
    {
		return nil;
    }
    
    mixUniform = [filterProgram uniformIndex:@"mixturePercent"];
    self.mix = 0.5;
    
    return self;
}


#pragma mark -
#pragma mark Accessors

- (void)setMix:(CGFloat)newValue;
{
    _mix = newValue;
    
    [self setFloat:_mix forUniform:mixUniform program:filterProgram];
}


@end

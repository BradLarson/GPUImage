#import "GPUImageLuminanceRangeFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageLuminanceRangeFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float rangeReduction;
 
 // Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
 const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     mediump float luminance = dot(textureColor.rgb, luminanceWeighting);
     mediump float luminanceRatio = ((0.5 - luminance) * rangeReduction);
     
     gl_FragColor = vec4((textureColor.rgb) + (luminanceRatio), textureColor.w);
 }
);
#else
NSString *const kGPUImageLuminanceRangeFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float rangeReduction;
 
 // Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
 const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     float luminance = dot(textureColor.rgb, luminanceWeighting);
     float luminanceRatio = ((0.5 - luminance) * rangeReduction);
     
     gl_FragColor = vec4((textureColor.rgb) + (luminanceRatio), textureColor.w);
 }
);
#endif

@implementation GPUImageLuminanceRangeFilter

@synthesize rangeReductionFactor = _rangeReductionFactor;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageLuminanceRangeFragmentShaderString]))
    {
		return nil;
    }
    
    rangeReductionUniform = [filterProgram uniformIndex:@"rangeReduction"];
    self.rangeReductionFactor = 0.6;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setRangeReductionFactor:(CGFloat)newValue;
{
    _rangeReductionFactor = newValue;
    
    [self setFloat:_rangeReductionFactor forUniform:rangeReductionUniform program:filterProgram];
}


@end

#import "GPUImageSaturationFilter.h"

NSString *const kGPUImageSaturationFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float saturation;
 
 // Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
 const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp float luminance = dot(textureColor.rgb, luminanceWeighting);
    lowp vec3 greyScaleColor = vec3(luminance);
    
	gl_FragColor = vec4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w);
	 
 }
);

@implementation GPUImageSaturationFilter

@synthesize saturation = _saturation;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSaturationFragmentShaderString]))
    {
		return nil;
    }
    
    saturationUniform = [filterProgram uniformIndex:@"saturation"];
    self.saturation = 1.0;

    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setSaturation:(CGFloat)newValue;
{
    _saturation = newValue;
    
    [self setFloat:_saturation forUniform:saturationUniform program:filterProgram];
}

@end


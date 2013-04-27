#import "GPUImageFalseColorFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUFalseColorFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float intensity;
 uniform vec3 firstColor;
 uniform vec3 secondColor;
 
 const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     float luminance = dot(textureColor.rgb, luminanceWeighting);
     
     gl_FragColor = vec4( mix(firstColor.rgb, secondColor.rgb, luminance), textureColor.a);
 }
);
#else
NSString *const kGPUFalseColorFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float intensity;
 uniform vec3 firstColor;
 uniform vec3 secondColor;
 
 const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     float luminance = dot(textureColor.rgb, luminanceWeighting);
     
     gl_FragColor = vec4( mix(firstColor.rgb, secondColor.rgb, luminance), textureColor.a);
 }
);
#endif


@implementation GPUImageFalseColorFilter

@synthesize secondColor = _secondColor;
@synthesize firstColor = _firstColor;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUFalseColorFragmentShaderString]))
    {
		return nil;
    }
    
    firstColorUniform = [filterProgram uniformIndex:@"firstColor"];
    secondColorUniform = [filterProgram uniformIndex:@"secondColor"];
    
	self.firstColor = (GPUVector4){0.0f, 0.0f, 0.5f, 1.0f};
	self.secondColor = (GPUVector4){1.0f, 0.0f, 0.0f, 1.0f};
    
    return self;
}


#pragma mark -
#pragma mark Accessors

- (void)setFirstColor:(GPUVector4)newValue;
{
	_firstColor = newValue;
	
	[self setFirstColorRed:_firstColor.one green:_firstColor.two blue:_firstColor.three];
}

- (void)setSecondColor:(GPUVector4)newValue;
{
	_secondColor = newValue;
	
	[self setSecondColorRed:_secondColor.one green:_secondColor.two blue:_secondColor.three];
}

- (void)setFirstColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;
{
    GPUVector3 firstColor = {redComponent, greenComponent, blueComponent};
    
    [self setVec3:firstColor forUniform:firstColorUniform program:filterProgram];
}

- (void)setSecondColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;
{
    GPUVector3 secondColor = {redComponent, greenComponent, blueComponent};
    
    [self setVec3:secondColor forUniform:secondColorUniform program:filterProgram];
}

@end

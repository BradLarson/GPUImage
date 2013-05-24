#import "GPUImageColorFilter.h"

NSString *const kGPUColorFragmentShaderString = SHADER_STRING
(
 precision lowp float;

 varying highp vec2 textureCoordinate;

 uniform sampler2D inputImageTexture;
 uniform vec3 filterColor;

 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     gl_FragColor = vec4(filterColor, textureColor.a);
 }
 );

@implementation GPUImageColorFilter

@synthesize color = _color;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUColorFragmentShaderString]))
    {
		return nil;
    }

    filterColorUniform = [filterProgram uniformIndex:@"filterColor"];

    self.color = (GPUVector4){1.0f, 1.0f, 1.0f, 1.0f};
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

@end

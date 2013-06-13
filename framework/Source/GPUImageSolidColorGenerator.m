#import "GPUImageSolidColorGenerator.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUSolidColorFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying highp vec2 textureCoordinate; 
 uniform sampler2D inputImageTexture;
 uniform vec4 color;
 uniform int useExistingAlpha;
 
 void main()
 {
     if (useExistingAlpha == 1)
     {
         lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
         gl_FragColor = vec4(color.rgb, textureColor.a);
     }
     else
     {
         gl_FragColor = color;
     }
 }
);
#else
NSString *const kGPUSolidColorFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate; 
 uniform sampler2D inputImageTexture;
 uniform vec4 color;
 uniform int useExistingAlpha;

 void main()
 {
     if (useExistingAlpha == 1)
     {
         lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
         gl_FragColor = vec4(color.rgb, textureColor.a);
     }
     else
     {
         gl_FragColor = color;
     }
 }
);
#endif

@implementation GPUImageSolidColorGenerator

@synthesize color = _color;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUSolidColorFragmentShaderString]))
    {
		return nil;
    }
    
    colorUniform = [filterProgram uniformIndex:@"color"];
    useExistingAlphaUniform = [filterProgram uniformIndex:@"useExistingAlpha"];
    
	self.color = (GPUVector4){0.0f, 0.0f, 0.5f, 1.0f};
    self.useExistingAlpha = NO;
    
    return self;
}


#pragma mark -
#pragma mark Accessors

- (void)setColor:(GPUVector4)newValue;
{
	[self setColorRed:newValue.one green:newValue.two blue:newValue.three alpha:newValue.four];
}

- (void)setColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
{
    _color.one = redComponent;
    _color.two = greenComponent;
    _color.three = blueComponent;
    _color.four = alphaComponent;
    
    [self setVec4:_color forUniform:colorUniform program:filterProgram];
}

- (void)setUseExistingAlpha:(BOOL)useExistingAlpha;
{
    _useExistingAlpha = useExistingAlpha;

    [self setInteger:(useExistingAlpha ? 1 : 0) forUniform:useExistingAlphaUniform program:filterProgram];
}

@end

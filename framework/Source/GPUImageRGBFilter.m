#import "GPUImageRGBFilter.h"

NSString *const kGPUImageRGBFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform highp float red;
 uniform highp float green;
 uniform highp float blue;
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(textureColor.r * red, textureColor.g * green, textureColor.b * blue, 1.0);
 }
 );

@implementation GPUImageRGBFilter

@synthesize red = _red, blue = _blue, green = _green;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageRGBFragmentShaderString]))
    {
		return nil;
    }
    
    redUniform = [filterProgram uniformIndex:@"red"];
    self.red = 1.0;
    
    greenUniform = [filterProgram uniformIndex:@"green"];
    self.green = 1.0;
    
    blueUniform = [filterProgram uniformIndex:@"blue"];
    self.blue = 1.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setRed:(CGFloat)newValue;
{
    _red = newValue;
    
    [self setFloat:_red forUniform:redUniform program:filterProgram];
}

- (void)setGreen:(CGFloat)newValue;
{
    _green = newValue;

    [self setFloat:_green forUniform:greenUniform program:filterProgram];
}

- (void)setBlue:(CGFloat)newValue;
{
    _blue = newValue;

    [self setFloat:_blue forUniform:blueUniform program:filterProgram];
}

@end
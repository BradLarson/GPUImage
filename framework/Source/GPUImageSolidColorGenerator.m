#import "GPUImageSolidColorGenerator.h"

NSString *const kGPUSolidColorFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform vec4 color;
 
 void main()
 {
     gl_FragColor = color;
 }
);

@implementation GPUImageSolidColorGenerator

@synthesize color = _color;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUSolidColorFragmentShaderString]))
    {
		return nil;
    }
    
    colorUniform = [filterProgram uniformIndex:@"color"];
    
	self.color = (GPUVector4){0.0f, 0.0f, 0.5f, 1.0f};
    
    return self;
}


#pragma mark -
#pragma mark Accessors

- (void)forceProcessingAtSize:(CGSize)frameSize;
{
    [super forceProcessingAtSize:frameSize];

    if (!CGSizeEqualToSize(inputTextureSize, CGSizeZero))
    {
        [self newFrameReadyAtTime:kCMTimeIndefinite atIndex:0];
    }
}

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    [super addTarget:newTarget atTextureLocation:textureLocation];
    
    if (!CGSizeEqualToSize(inputTextureSize, CGSizeZero))
    {
        [newTarget setInputSize:inputTextureSize atIndex:textureLocation];
        [newTarget newFrameReadyAtTime:kCMTimeIndefinite atIndex:textureLocation];
    }
}

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
    
    if (!CGSizeEqualToSize(inputTextureSize, CGSizeZero))
    {
        [self newFrameReadyAtTime:kCMTimeIndefinite atIndex:0];
    }
}

@end

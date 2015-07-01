#import "GPUImageSolidColorGenerator.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUSolidColorFragmentShaderString = SHADER_STRING
(
 precision lowp float;

 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform vec4 color;
 uniform float useExistingAlpha;

 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     gl_FragColor = vec4(color.rgb, max(textureColor.a, 1.0 - useExistingAlpha));
 }
 );
#else
NSString *const kGPUSolidColorFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform vec4 color;
 uniform float useExistingAlpha;

 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     gl_FragColor = vec4(color.rgb, max(textureColor.a, 1.0 - useExistingAlpha));
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
    
	_color = (GPUVector4){0.0f, 0.0f, 0.5f, 1.0f};
    self.useExistingAlpha = NO;
    
    return self;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    if (self.preventRendering)
    {
        return;
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:filterProgram];
        
        outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
        [outputFramebuffer activateFramebuffer];
        
        glClearColor(_color.one, _color.two, _color.three, _color.four);
        glClear(GL_COLOR_BUFFER_BIT);
    });
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

- (void)setColorRed:(CGFloat)redComponent green:(CGFloat)greenComponent blue:(CGFloat)blueComponent alpha:(CGFloat)alphaComponent;
{
    _color.one = (GLfloat)redComponent;
    _color.two = (GLfloat)greenComponent;
    _color.three = (GLfloat)blueComponent;
    _color.four = (GLfloat)alphaComponent;
    
//    [self setVec4:_color forUniform:colorUniform program:filterProgram];
    runAsynchronouslyOnVideoProcessingQueue(^{
        [self newFrameReadyAtTime:kCMTimeIndefinite atIndex:0];
    });
}

- (void)setUseExistingAlpha:(BOOL)useExistingAlpha;
{
    _useExistingAlpha = useExistingAlpha;

    [self setInteger:(useExistingAlpha ? 1 : 0) forUniform:useExistingAlphaUniform program:filterProgram];
}

@end

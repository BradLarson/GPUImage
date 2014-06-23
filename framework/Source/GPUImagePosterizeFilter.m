#import "GPUImagePosterizeFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImagePosterizeFragmentShaderString = SHADER_STRING
( 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform highp float colorLevels;
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = floor((textureColor * colorLevels) + vec4(0.5)) / colorLevels;
 }
);
#else
NSString *const kGPUImagePosterizeFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float colorLevels;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = floor((textureColor * colorLevels) + vec4(0.5)) / colorLevels;
 }
);
#endif

@implementation GPUImagePosterizeFilter

@synthesize colorLevels = _colorLevels;

#pragma mark -
#pragma mark Initialization

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImagePosterizeFragmentShaderString]))
    {
		return nil;
    }
    
    colorLevelsUniform = [filterProgram uniformIndex:@"colorLevels"];
    self.colorLevels = 10;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setColorLevels:(NSUInteger)newValue;
{
    _colorLevels = newValue;
    
    [self setFloat:_colorLevels forUniform:colorLevelsUniform program:filterProgram];
}

@end


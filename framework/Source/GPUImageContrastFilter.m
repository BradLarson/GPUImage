#import "GPUImageContrastFilter.h"

NSString *const kGPUImageContrastFragmentShaderString = SHADER_STRING
( 
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float contrast;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(((textureColor.rgb - vec3(0.5)) * contrast + vec3(0.5)), textureColor.w);
 }
);

@implementation GPUImageContrastFilter

@synthesize contrast = _contrast;

#pragma mark -
#pragma mark Initialization

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageContrastFragmentShaderString]))
    {
		return nil;
    }
    
    contrastUniform = [filterProgram uniformIndex:@"contrast"];
    self.contrast = 1.0;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setContrast:(CGFloat)newValue;
{
    _contrast = newValue;
    
    [self setFloat:_contrast forUniform:contrastUniform program:filterProgram];
}

@end


#import "GPUImageVignetteFilter.h"

NSString *const kGPUImageVignetteFragmentShaderString = SHADER_STRING
(
 uniform sampler2D inputImageTexture;
 varying highp vec2 textureCoordinate;
 
 uniform highp float vignetteX;
 uniform highp float vignetteY;
 
 void main()
{
    lowp vec3 rgb = texture2D(inputImageTexture, textureCoordinate).xyz;
    lowp float d = distance(textureCoordinate, vec2(0.5,0.5));
    rgb *= smoothstep(vignetteX, vignetteY, d);
    gl_FragColor = vec4(vec3(rgb),1.0);
}
 );


@implementation GPUImageVignetteFilter

@synthesize x=_x, y=_y;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageVignetteFragmentShaderString]))
    {
		return nil;
    }
    
    xUniform = [filterProgram uniformIndex:@"vignetteX"];
    yUniform = [filterProgram uniformIndex:@"vignetteY"];
    
    self.x = 0.75;
    self.y = 0.50;
    
    return self;
}

- (void) setX:(CGFloat)x {
    _x = x;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(xUniform, _x);
}

- (void) setY:(CGFloat)y {
    _y = y;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(yUniform, _y);
}

@end

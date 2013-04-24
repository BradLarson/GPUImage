#import "GPUImageZoomBlurFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageZoomBlurFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp vec2 blurCenter;
 uniform highp float blurSize;
 
 void main()
 {
     // TODO: Do a more intelligent scaling based on resolution here
     highp vec2 samplingOffset = 1.0/100.0 * (blurCenter - textureCoordinate) * blurSize;
     
     lowp vec4 fragmentColor = texture2D(inputImageTexture, textureCoordinate) * 0.18;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate + samplingOffset) * 0.15;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate + (2.0 * samplingOffset)) *  0.12;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate + (3.0 * samplingOffset)) * 0.09;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate + (4.0 * samplingOffset)) * 0.05;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate - samplingOffset) * 0.15;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate - (2.0 * samplingOffset)) *  0.12;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate - (3.0 * samplingOffset)) * 0.09;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate - (4.0 * samplingOffset)) * 0.05;
     
     gl_FragColor = fragmentColor;
 }
);
#else
NSString *const kGPUImageZoomBlurFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform vec2 blurCenter;
 uniform float blurSize;
 
 void main()
 {
     // TODO: Do a more intelligent scaling based on resolution here
     vec2 samplingOffset = 1.0/100.0 * (blurCenter - textureCoordinate) * blurSize;
     
     vec4 fragmentColor = texture2D(inputImageTexture, textureCoordinate) * 0.18;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate + samplingOffset) * 0.15;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate + (2.0 * samplingOffset)) *  0.12;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate + (3.0 * samplingOffset)) * 0.09;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate + (4.0 * samplingOffset)) * 0.05;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate - samplingOffset) * 0.15;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate - (2.0 * samplingOffset)) *  0.12;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate - (3.0 * samplingOffset)) * 0.09;
     fragmentColor += texture2D(inputImageTexture, textureCoordinate - (4.0 * samplingOffset)) * 0.05;
     
     gl_FragColor = fragmentColor;
 }
);
#endif

@interface GPUImageZoomBlurFilter()
{
    GLint blurSizeUniform, blurCenterUniform;
}
@end

@implementation GPUImageZoomBlurFilter

@synthesize blurSize = _blurSize;
@synthesize blurCenter = _blurCenter;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageZoomBlurFragmentShaderString]))
    {
        return nil;
    }
    
    blurSizeUniform = [filterProgram uniformIndex:@"blurSize"];
    blurCenterUniform = [filterProgram uniformIndex:@"blurCenter"];
    
    self.blurSize = 1.0;
    self.blurCenter = CGPointMake(0.5, 0.5);
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    [super setInputRotation:newInputRotation atIndex:textureIndex];
    [self setBlurCenter:self.blurCenter];
}

- (void)setBlurSize:(CGFloat)newValue;
{
    _blurSize = newValue;
    
    [self setFloat:_blurSize forUniform:blurSizeUniform program:filterProgram];
}

- (void)setBlurCenter:(CGPoint)newValue;
{
    _blurCenter = newValue;
    
    CGPoint rotatedPoint = [self rotatedPoint:_blurCenter forRotation:inputRotation];
    [self setPoint:rotatedPoint forUniform:blurCenterUniform program:filterProgram];
}

@end

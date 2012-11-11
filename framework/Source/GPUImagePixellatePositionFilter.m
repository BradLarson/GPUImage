#import "GPUImagePixellatePositionFilter.h"

NSString *const kGPUImagePixellationPositionFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp float fractionalWidthOfPixel;
 uniform highp float aspectRatio;
 uniform lowp vec2 pixelateCenter;
 uniform highp float pixelateRadius;
 
 void main()
 {
     highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     highp float dist = distance(pixelateCenter, textureCoordinateToUse);

     if (dist < pixelateRadius)
     {
         highp vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / aspectRatio);
         highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor) + 0.5 * sampleDivisor;
         gl_FragColor = texture2D(inputImageTexture, samplePos );
     }
     else
     {
         gl_FragColor = texture2D(inputImageTexture, textureCoordinate );
     }
 }
);

@interface GPUImagePixellatePositionFilter ()

@property (readwrite, nonatomic) CGFloat aspectRatio;

@end

@implementation GPUImagePixellatePositionFilter

@synthesize fractionalWidthOfAPixel = _fractionalWidthOfAPixel;
@synthesize aspectRatio = _aspectRatio;
@synthesize center = _center;
@synthesize radius = _radius;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kGPUImagePixellationPositionFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super initWithFragmentShaderFromString:fragmentShaderString]))
    {
		return nil;
    }
    
    fractionalWidthOfAPixelUniform = [filterProgram uniformIndex:@"fractionalWidthOfPixel"];
    aspectRatioUniform = [filterProgram uniformIndex:@"aspectRatio"];
    centerUniform = [filterProgram uniformIndex:@"pixelateCenter"];
    radiusUniform = [filterProgram uniformIndex:@"pixelateRadius"];
    
    self.fractionalWidthOfAPixel = 0.05;
    self.center = CGPointMake(0.5f, 0.5f);
    self.radius = 1.0f;
    
    return self;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    CGSize oldInputSize = inputTextureSize;
    [super setInputSize:newSize atIndex:textureIndex];
    
    if ( (!CGSizeEqualToSize(oldInputSize, inputTextureSize)) && (!CGSizeEqualToSize(newSize, CGSizeZero)) )
    {
        if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
        {
            [self setAspectRatio:(inputTextureSize.width / inputTextureSize.height)];
        }
        else
        {
            [self setAspectRatio:(inputTextureSize.height / inputTextureSize.width)];
        }
    }
}

#pragma mark -
#pragma mark Accessors

- (void)setFractionalWidthOfAPixel:(CGFloat)newValue;
{
    CGFloat singlePixelSpacing;
    if (inputTextureSize.width != 0.0)
    {
        singlePixelSpacing = 1.0 / inputTextureSize.width;
    }
    else
    {
        singlePixelSpacing = 1.0 / 2048.0;
    }
    
    if (newValue < singlePixelSpacing)
    {
        _fractionalWidthOfAPixel = singlePixelSpacing;
    }
    else
    {
        _fractionalWidthOfAPixel = newValue;
    }
    
    [self setFloat:_fractionalWidthOfAPixel forUniform:fractionalWidthOfAPixelUniform program:filterProgram];
}

- (void)setAspectRatio:(CGFloat)newValue;
{
    _aspectRatio = newValue;

    [self setFloat:_aspectRatio forUniform:aspectRatioUniform program:filterProgram];
}

- (void)setCenter:(CGPoint)center
{
    _center = center;
    
    [self setPoint:_center forUniform:centerUniform program:filterProgram];
}

- (void)setRadius:(CGFloat)radius
{
    _radius = radius;
    
    [self setFloat:_radius forUniform:radiusUniform program:filterProgram];
}

@end

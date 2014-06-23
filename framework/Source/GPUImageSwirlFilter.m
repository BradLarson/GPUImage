#import "GPUImageSwirlFilter.h"

// Adapted from the shader example here: http://www.geeks3d.com/20110428/shader-library-swirl-post-processing-filter-in-glsl/
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageSwirlFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp vec2 center;
 uniform highp float radius;
 uniform highp float angle;
 
 void main()
 {
     highp vec2 textureCoordinateToUse = textureCoordinate;
     highp float dist = distance(center, textureCoordinate);
     if (dist < radius)
     {
         textureCoordinateToUse -= center;
         highp float percent = (radius - dist) / radius;
         highp float theta = percent * percent * angle * 8.0;
         highp float s = sin(theta);
         highp float c = cos(theta);
         textureCoordinateToUse = vec2(dot(textureCoordinateToUse, vec2(c, -s)), dot(textureCoordinateToUse, vec2(s, c)));
         textureCoordinateToUse += center;
     }
    
     gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
     
 }
);
#else
NSString *const kGPUImageSwirlFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform vec2 center;
 uniform float radius;
 uniform float angle;
 
 void main()
 {
     vec2 textureCoordinateToUse = textureCoordinate;
     float dist = distance(center, textureCoordinate);
     if (dist < radius)
     {
         textureCoordinateToUse -= center;
         float percent = (radius - dist) / radius;
         float theta = percent * percent * angle * 8.0;
         float s = sin(theta);
         float c = cos(theta);
         textureCoordinateToUse = vec2(dot(textureCoordinateToUse, vec2(c, -s)), dot(textureCoordinateToUse, vec2(s, c)));
         textureCoordinateToUse += center;
     }
     
     gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
 }
);
#endif

@implementation GPUImageSwirlFilter

@synthesize center = _center;
@synthesize radius = _radius;
@synthesize angle = _angle;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSwirlFragmentShaderString]))
    {
		return nil;
    }
    
    radiusUniform = [filterProgram uniformIndex:@"radius"];
    angleUniform = [filterProgram uniformIndex:@"angle"];
    centerUniform = [filterProgram uniformIndex:@"center"];

    self.radius = 0.5;
    self.angle = 1.0;
    self.center = CGPointMake(0.5, 0.5);

    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    [super setInputRotation:newInputRotation atIndex:textureIndex];
    [self setCenter:self.center];
}

- (void)setRadius:(CGFloat)newValue;
{
    _radius = newValue;
    
    [self setFloat:_radius forUniform:radiusUniform program:filterProgram];
}

- (void)setAngle:(CGFloat)newValue;
{
    _angle = newValue;

    [self setFloat:_angle forUniform:angleUniform program:filterProgram];
}

- (void)setCenter:(CGPoint)newValue;
{
    _center = newValue;
    
    CGPoint rotatedPoint = [self rotatedPoint:_center forRotation:inputRotation];
    [self setPoint:rotatedPoint forUniform:centerUniform program:filterProgram];
}

@end

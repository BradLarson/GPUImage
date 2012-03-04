#import "GPUImageSwirlFilter.h"

// Adapted from the shader example here: http://www.geeks3d.com/20110428/shader-library-swirl-post-processing-filter-in-glsl/

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
     textureCoordinateToUse -= center;
     if (dist < radius)
     {
         highp float percent = (radius - dist) / radius;
         highp float theta = percent * percent * angle * 8.0;
         highp float s = sin(theta);
         highp float c = cos(theta);
         textureCoordinateToUse = vec2(dot(textureCoordinateToUse, vec2(c, -s)), dot(textureCoordinateToUse, vec2(s, c)));
     }
     textureCoordinateToUse += center;
    
     gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
     
 }
);

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

- (void)setRadius:(CGFloat)newValue;
{
    _radius = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(radiusUniform, _radius);
}

- (void)setAngle:(CGFloat)newValue;
{
    _angle = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(angleUniform, _angle);
}

- (void)setCenter:(CGPoint)newValue;
{
    _center = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    
    GLfloat centerPosition[2];
    centerPosition[0] = _center.x;
    centerPosition[1] = _center.y;
    
    glUniform2fv(centerUniform, 1, centerPosition);
}

@end

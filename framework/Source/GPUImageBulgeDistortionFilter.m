#import "GPUImageBulgeDistortionFilter.h"

NSString *const kGPUImageBulgeDistortionFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp vec2 center;
 uniform highp float radius;
 uniform highp float scale;
 
 void main()
 {
     highp vec2 textureCoordinateToUse = textureCoordinate;
     highp float dist = distance(center, textureCoordinate);
     textureCoordinateToUse -= center;
     if (dist < radius)
     {
         highp float percent = 1.0 - ((radius - dist) / radius) * scale;
         percent = percent * percent;
         
         textureCoordinateToUse = textureCoordinateToUse * percent;
     }
     textureCoordinateToUse += center;
    
     gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
     
 }
);

@implementation GPUImageBulgeDistortionFilter

@synthesize center = _center;
@synthesize radius = _radius;
@synthesize scale = _scale;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageBulgeDistortionFragmentShaderString]))
    {
		return nil;
    }
    
    radiusUniform = [filterProgram uniformIndex:@"radius"];
    scaleUniform = [filterProgram uniformIndex:@"scale"];
    centerUniform = [filterProgram uniformIndex:@"center"];

    self.radius = 0.25;
    self.scale = 0.5;
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

- (void)setScale:(CGFloat)newValue;
{
    _scale = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(scaleUniform, _scale);
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

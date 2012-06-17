#import "GPUImageSphereRefractionFilter.h"

NSString *const kGPUImageSphereRefractionFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp vec2 center;
 uniform highp float radius;
 uniform highp float scale;
 const highp float eta = 0.2;
 
 void main()
 {
     highp vec2 textureCoordinateToUse = textureCoordinate;
     highp float distanceFromCenter = distance(center, textureCoordinate);
     lowp float checkForPresenceWithinSphere = step(distanceFromCenter, radius);
     
     highp float normalizedDepth = sqrt(1.0 - distanceFromCenter * distanceFromCenter);
     highp vec3 sphereNormal = normalize(vec3(textureCoordinate - center, normalizedDepth));
     
     highp vec3 refractedVector = refract(vec3(0.0, 0.0, -1.0), sphereNormal, eta);
     
//     gl_FragColor = texture2D(inputImageTexture, refractedVector.xy) * checkForPresenceWithinSphere;     
     gl_FragColor = vec4(sphereNormal * checkForPresenceWithinSphere, 1.0);     
 }
);


@implementation GPUImageSphereRefractionFilter

@synthesize center = _center;
@synthesize radius = _radius;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSphereRefractionFragmentShaderString]))
    {
		return nil;
    }
    
    radiusUniform = [filterProgram uniformIndex:@"radius"];
    scaleUniform = [filterProgram uniformIndex:@"scale"];
    centerUniform = [filterProgram uniformIndex:@"center"];
    
    self.radius = 0.5;
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
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(radiusUniform, _radius);
}

- (void)setCenter:(CGPoint)newValue;
{
    _center = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    
    CGPoint rotatedPoint = [self rotatedPoint:_center forRotation:inputRotation];
    
    GLfloat centerPosition[2];
    centerPosition[0] = rotatedPoint.x;
    centerPosition[1] = rotatedPoint.y;
    
    glUniform2fv(centerUniform, 1, centerPosition);
}

@end

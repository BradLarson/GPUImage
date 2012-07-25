#import "GPUImageSphereRefractionFilter.h"

NSString *const kGPUImageSphereRefractionFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp vec2 center;
 uniform highp float radius;
 uniform highp float aspectRatio;
 uniform highp float refractiveIndex;
 
 void main()
 {
     highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     highp float distanceFromCenter = distance(center, textureCoordinateToUse);
     lowp float checkForPresenceWithinSphere = step(distanceFromCenter, radius);
     
     distanceFromCenter = distanceFromCenter / radius;
     
     highp float normalizedDepth = radius * sqrt(1.0 - distanceFromCenter * distanceFromCenter);
     highp vec3 sphereNormal = normalize(vec3(textureCoordinateToUse - center, normalizedDepth));
     
     highp vec3 refractedVector = refract(vec3(0.0, 0.0, -1.0), sphereNormal, refractiveIndex);
     
     gl_FragColor = texture2D(inputImageTexture, (refractedVector.xy + 1.0) * 0.5) * checkForPresenceWithinSphere;     
 }
);

@interface GPUImageSphereRefractionFilter ()

@property (readwrite, nonatomic) CGFloat aspectRatio;

@end


@implementation GPUImageSphereRefractionFilter

@synthesize center = _center;
@synthesize radius = _radius;
@synthesize aspectRatio = _aspectRatio;
@synthesize refractiveIndex = _refractiveIndex;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [self initWithFragmentShaderFromString:kGPUImageSphereRefractionFragmentShaderString]))
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
    
    radiusUniform = [filterProgram uniformIndex:@"radius"];
    aspectRatioUniform = [filterProgram uniformIndex:@"aspectRatio"];
    centerUniform = [filterProgram uniformIndex:@"center"];
    refractiveIndexUniform = [filterProgram uniformIndex:@"refractiveIndex"];
    
    self.radius = 0.25;
    self.center = CGPointMake(0.5, 0.5);
    self.refractiveIndex = 0.71;
    
    [self setBackgroundColorRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    
    return self;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    CGSize oldInputSize = inputTextureSize;
    [super setInputSize:newSize atIndex:textureIndex];

    if (!CGSizeEqualToSize(oldInputSize, inputTextureSize))
    {
        [self setAspectRatio:(inputTextureSize.width / inputTextureSize.height)];
    }
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

- (void)setAspectRatio:(CGFloat)newValue;
{
    _aspectRatio = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(aspectRatioUniform, _aspectRatio);
}

- (void)setRefractiveIndex:(CGFloat)newValue;
{
    _refractiveIndex = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(refractiveIndexUniform, _refractiveIndex);
}

@end

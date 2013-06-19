#import "GPUImageSphereRefractionFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
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
#else
NSString *const kGPUImageSphereRefractionFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform vec2 center;
 uniform float radius;
 uniform float aspectRatio;
 uniform float refractiveIndex;
 
 void main()
 {
     vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
     float distanceFromCenter = distance(center, textureCoordinateToUse);
     float checkForPresenceWithinSphere = step(distanceFromCenter, radius);
     
     distanceFromCenter = distanceFromCenter / radius;
     
     float normalizedDepth = radius * sqrt(1.0 - distanceFromCenter * distanceFromCenter);
     vec3 sphereNormal = normalize(vec3(textureCoordinateToUse - center, normalizedDepth));
     
     vec3 refractedVector = refract(vec3(0.0, 0.0, -1.0), sphereNormal, refractiveIndex);
     
     gl_FragColor = texture2D(inputImageTexture, (refractedVector.xy + 1.0) * 0.5) * checkForPresenceWithinSphere;
 }
);
#endif

@interface GPUImageSphereRefractionFilter ()

- (void)adjustAspectRatio;

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

    if (!CGSizeEqualToSize(oldInputSize, inputTextureSize) && (!CGSizeEqualToSize(newSize, CGSizeZero)) )
    {
        [self adjustAspectRatio];
    }
}

#pragma mark -
#pragma mark Accessors

- (void)adjustAspectRatio;
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

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    [super setInputRotation:newInputRotation atIndex:textureIndex];
    [self setCenter:self.center];
    [self adjustAspectRatio];
}

- (void)forceProcessingAtSize:(CGSize)frameSize;
{
    [super forceProcessingAtSize:frameSize];
    [self adjustAspectRatio];
}

- (void)setRadius:(CGFloat)newValue;
{
    _radius = newValue;
    
    [self setFloat:_radius forUniform:radiusUniform program:filterProgram];
}

- (void)setCenter:(CGPoint)newValue;
{
    _center = newValue;
    
    CGPoint rotatedPoint = [self rotatedPoint:_center forRotation:inputRotation];
    [self setPoint:rotatedPoint forUniform:centerUniform program:filterProgram];
}

- (void)setAspectRatio:(CGFloat)newValue;
{
    _aspectRatio = newValue;
    
    [self setFloat:_aspectRatio forUniform:aspectRatioUniform program:filterProgram];
}

- (void)setRefractiveIndex:(CGFloat)newValue;
{
    _refractiveIndex = newValue;

    [self setFloat:_refractiveIndex forUniform:refractiveIndexUniform program:filterProgram];
}

@end

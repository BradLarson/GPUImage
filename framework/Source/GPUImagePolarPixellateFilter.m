#import "GPUImagePolarPixellateFilter.h"

// @fattjake based on vid by toneburst

NSString *const kGPUImagePolarPixellateFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp vec2 center;
 uniform highp vec2 pixelSize;

 
 void main()
 {
     highp vec2 normCoord = 2.0 * textureCoordinate - 1.0;
     highp vec2 normCenter = 2.0 * center - 1.0;
     
     normCoord -= normCenter;
     
     highp float r = length(normCoord); // to polar coords 
     highp float phi = atan(normCoord.y, normCoord.x); // to polar coords 
     
     r = r - mod(r, pixelSize.x) + 0.03;
     phi = phi - mod(phi, pixelSize.y);
           
     normCoord.x = r * cos(phi);
     normCoord.y = r * sin(phi);
      
     normCoord += normCenter;
     
     mediump vec2 textureCoordinateToUse = normCoord / 2.0 + 0.5;
     
     gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
     
 }
 );


@implementation GPUImagePolarPixellateFilter

@synthesize center = _center;

@synthesize pixelSize = _pixelSize;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImagePolarPixellateFragmentShaderString]))
    {
		return nil;
    }
    
    pixelSizeUniform = [filterProgram uniformIndex:@"pixelSize"];
    centerUniform = [filterProgram uniformIndex:@"center"];
    
    
    self.pixelSize = CGSizeMake(0.05, 0.05);
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

- (void)setPixelSize:(CGSize)pixelSize 
{
    _pixelSize = pixelSize;
    
    [self setSize:_pixelSize forUniform:pixelSizeUniform program:filterProgram];
}

- (void)setCenter:(CGPoint)newValue;
{
    _center = newValue;
    
    CGPoint rotatedPoint = [self rotatedPoint:_center forRotation:inputRotation];
    [self setPoint:rotatedPoint forUniform:centerUniform program:filterProgram];
}

@end

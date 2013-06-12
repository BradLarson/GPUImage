#import "GPUImageHazeFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageHazeFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform lowp float hazeDistance;
 uniform highp float slope;
 
 void main()
 {
	//todo reconsider precision modifiers	 
	 highp vec4 color = vec4(1.0);//todo reimplement as a parameter
	 
	 highp float  d = textureCoordinate.y * slope  +  hazeDistance;
	 
	 highp vec4 c = texture2D(inputImageTexture, textureCoordinate) ; // consider using unpremultiply
	 
	 c = (c - d * color) / (1.0 -d);
	 
	 gl_FragColor = c; //consider using premultiply(c);
 }
);
#else
NSString *const kGPUImageHazeFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform float hazeDistance;
 uniform float slope;
 
 void main()
 {
     //todo reconsider precision modifiers
	 vec4 color = vec4(1.0);//todo reimplement as a parameter
	 
	 float  d = textureCoordinate.y * slope  +  hazeDistance;
	 
	 vec4 c = texture2D(inputImageTexture, textureCoordinate) ; // consider using unpremultiply
	 	 
	 c = (c - d * color) / (1.0 -d);
	 
	 gl_FragColor = c; //consider using premultiply(c);
 }
);
#endif




@implementation GPUImageHazeFilter

@synthesize distance = _distance;
@synthesize slope = _slope;
#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageHazeFragmentShaderString]))
    {
		return nil;
    }
    
    distanceUniform = [filterProgram uniformIndex:@"hazeDistance"];
	slopeUniform = [filterProgram uniformIndex:@"slope"];
	
    self.distance = 0.2;
    self.slope = 0.0;
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setDistance:(CGFloat)newValue;
{
    _distance = newValue;
    
    [self setFloat:_distance forUniform:distanceUniform program:filterProgram];
}

- (void)setSlope:(CGFloat)newValue;
{
    _slope = newValue;
    
    [self setFloat:_slope forUniform:slopeUniform program:filterProgram];
}

@end


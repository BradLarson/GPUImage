#import "GPUImageToneCurveFilter.h"

#pragma mark -
#pragma mark GPUImageACVFile Helper

//  GPUImageACVFile
//
//  ACV File format Parser
//  Please refer to http://www.adobe.com/devnet-apps/photoshop/fileformatashtml/PhotoshopFileFormats.htm#50577411_pgfId-1056330
//

@interface GPUImageACVFile : NSObject{
    short version;
    short totalCurves;
    
    NSArray *rgbCompositeCurvePoints;
    NSArray *redCurvePoints;
    NSArray *greenCurvePoints;    
    NSArray *blueCurvePoints;
}

@property(strong,nonatomic) NSArray *rgbCompositeCurvePoints;
@property(strong,nonatomic) NSArray *redCurvePoints;
@property(strong,nonatomic) NSArray *greenCurvePoints;    
@property(strong,nonatomic) NSArray *blueCurvePoints;

- (id) initWithCurveFile:(NSString*)curveFile;

@end

@implementation GPUImageACVFile

@synthesize rgbCompositeCurvePoints, redCurvePoints, greenCurvePoints, blueCurvePoints;

- (id) initWithCurveFile:(NSString*)curveFile
{    
    self = [super init];
	if (self != nil)
	{
        NSString *bundleCurvePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: curveFile];
        
        NSFileHandle* file = [NSFileHandle fileHandleForReadingAtPath: bundleCurvePath];
        
        if (file == nil)
        {
            NSLog(@"Failed to open file");
            
            return self;
        }
        
        NSData *databuffer;
        
        // 2 bytes, Version ( = 1 or = 4)
        databuffer = [file readDataOfLength: 2];
        version = CFSwapInt16BigToHost(*(int*)([databuffer bytes]));
        
        // 2 bytes, Count of curves in the file.
        [file seekToFileOffset:2];
        databuffer = [file readDataOfLength:2];
        totalCurves = CFSwapInt16BigToHost(*(int*)([databuffer bytes]));
        
        NSMutableArray *curves = [NSMutableArray new];
        
        float pointRate = (1.0 / 255);
        // The following is the data for each curve specified by count above
        for (NSInteger x = 0; x<totalCurves; x++)
        {
            // 2 bytes, Count of points in the curve (short integer from 2...19)
            databuffer = [file readDataOfLength:2];            
            short pointCount = CFSwapInt16BigToHost(*(int*)([databuffer bytes]));
            
            NSMutableArray *points = [NSMutableArray new];
            // point count * 4
            // Curve points. Each curve point is a pair of short integers where 
            // the first number is the output value (vertical coordinate on the 
            // Curves dialog graph) and the second is the input value. All coordinates have range 0 to 255. 
            for (NSInteger y = 0; y<pointCount; y++)
            {
                databuffer = [file readDataOfLength:2];
                short y = CFSwapInt16BigToHost(*(int*)([databuffer bytes]));
                databuffer = [file readDataOfLength:2];
                short x = CFSwapInt16BigToHost(*(int*)([databuffer bytes]));
                
                [points addObject:[NSValue valueWithCGSize:CGSizeMake(x * pointRate, y * pointRate)]];
            }
            
            [curves addObject:points];
        }
        
        [file closeFile];
        
        rgbCompositeCurvePoints = [curves objectAtIndex:0];
        redCurvePoints = [curves objectAtIndex:1];
        greenCurvePoints = [curves objectAtIndex:2];
        blueCurvePoints = [curves objectAtIndex:3];
	}
	
	return self;
    
}

@end

#pragma mark -
#pragma mark GPUImageToneCurveFilter Implementation

NSString *const kGPUImageToneCurveFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D toneCurveTexture;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     lowp float redCurveValue = texture2D(toneCurveTexture, vec2(textureColor.r, 0.0)).r;
     lowp float greenCurveValue = texture2D(toneCurveTexture, vec2(textureColor.g, 0.0)).g;
     lowp float blueCurveValue = texture2D(toneCurveTexture, vec2(textureColor.b, 0.0)).b;
     
     gl_FragColor = vec4(redCurveValue, greenCurveValue, blueCurveValue, textureColor.a);
 }
);


@interface GPUImageToneCurveFilter()
{
    GLint toneCurveTextureUniform;
    GLuint toneCurveTexture;
    GLubyte *toneCurveByteArray;
    
    NSArray *_redCurve, *_greenCurve, *_blueCurve, *_rgbCompositeCurve;
}

@end

@implementation GPUImageToneCurveFilter

@synthesize rgbCompositeControlPoints = _rgbCompositeControlPoints;
@synthesize redControlPoints = _redControlPoints;
@synthesize greenControlPoints = _greenControlPoints;
@synthesize blueControlPoints = _blueControlPoints;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageToneCurveFragmentShaderString]))
    {
		return nil;
    }
    
    toneCurveTextureUniform = [filterProgram uniformIndex:@"toneCurveTexture"];    
    
    NSArray *defaultCurve = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)], [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)], nil];
    [self setRgbCompositeControlPoints:defaultCurve];
    [self setRedControlPoints:defaultCurve];
    [self setGreenControlPoints:defaultCurve];
    [self setBlueControlPoints:defaultCurve];
    
    return self;
}

// This pulls in Adobe ACV curve files to specify the tone curve
- (id)initWithACV:(NSString*)curveFile
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageToneCurveFragmentShaderString]))
    {
		return nil;
    }
    
    toneCurveTextureUniform = [filterProgram uniformIndex:@"toneCurveTexture"];    
    
    GPUImageACVFile *curve = [[GPUImageACVFile alloc] initWithCurveFile:curveFile];

    [self setRgbCompositeControlPoints:curve.rgbCompositeCurvePoints];
    [self setRedControlPoints:curve.redCurvePoints];
    [self setGreenControlPoints:curve.greenCurvePoints];
    [self setBlueControlPoints:curve.blueCurvePoints];
    
    curve = nil;
    
    return self;
}

- (void)setPointsWithACV:(NSString*)curveFile
{
    GPUImageACVFile *curve = [[GPUImageACVFile alloc] initWithCurveFile:curveFile];
    
    [self setRgbCompositeControlPoints:curve.rgbCompositeCurvePoints];
    [self setRedControlPoints:curve.redCurvePoints];
    [self setGreenControlPoints:curve.greenCurvePoints];
    [self setBlueControlPoints:curve.blueCurvePoints];
    
    curve = nil;
}

- (void)dealloc
{
    if (toneCurveTexture)
    {
        glDeleteTextures(1, &toneCurveTexture);
        toneCurveTexture = 0;
        free(toneCurveByteArray);
    }
}

#pragma mark -
#pragma mark Curve calculation

- (NSArray *)getPreparedSplineCurve:(NSArray *)points
{
    if (points && [points count] > 0) 
    {
        // Sort the array.
        NSArray *sortedPoints = [points sortedArrayUsingComparator:^(id a, id b) {
            float x1 = [(NSValue *)a CGPointValue].x;
            float x2 = [(NSValue *)b CGPointValue].x;            
            return x1 > x2;
        }];
                
        // Convert from (0, 1) to (0, 255).
        NSMutableArray *convertedPoints = [NSMutableArray arrayWithCapacity:[sortedPoints count]];
        for (int i=0; i<[points count]; i++){
            CGPoint point = [[sortedPoints objectAtIndex:i] CGPointValue];
            point.x = point.x * 255;
            point.y = point.y * 255;
                        
            [convertedPoints addObject:[NSValue valueWithCGPoint:point]];
        }
        
        
        NSMutableArray *splinePoints = [self splineCurve:convertedPoints];
        
        // If we have a first point like (0.3, 0) we'll be missing some points at the beginning
        // that should be 0.
        CGPoint firstSplinePoint = [[splinePoints objectAtIndex:0] CGPointValue];
        
        if (firstSplinePoint.x > 0) {
            for (int i=0; i <=firstSplinePoint.x; i++) {
                CGPoint newCGPoint = CGPointMake(0, 0);
                [splinePoints insertObject:[NSValue valueWithCGPoint:newCGPoint] atIndex:0];
            }
        }
        
        
        // Prepare the spline points.
        NSMutableArray *preparedSplinePoints = [NSMutableArray arrayWithCapacity:[splinePoints count]];
        for (int i=0; i<[splinePoints count]; i++) 
        {
            CGPoint newPoint = [[splinePoints objectAtIndex:i] CGPointValue];
            CGPoint origPoint = CGPointMake(newPoint.x, newPoint.x);
            
            float distance = sqrt(pow((origPoint.x - newPoint.x), 2.0) + pow((origPoint.y - newPoint.y), 2.0));
            
            if (origPoint.y > newPoint.y) 
            {
                distance = -distance;
            }
            
            [preparedSplinePoints addObject:[NSNumber numberWithFloat:distance]];
        }
        
        return preparedSplinePoints;
    }
    
    return nil;
}


- (NSMutableArray *)splineCurve:(NSArray *)points
{
    NSMutableArray *sdA = [self secondDerivative:points];
    
    // Is [points count] equal to [sdA count]?
//    int n = [points count];
    int n = [sdA count];
    double sd[n];
    
    // From NSMutableArray to sd[n];
    for (int i=0; i<n; i++) 
    {
        sd[i] = [[sdA objectAtIndex:i] doubleValue];
    }
    
    
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:(n+1)];
                              
    for(int i=0; i<n-1 ; i++) 
    {
        CGPoint cur = [[points objectAtIndex:i] CGPointValue];
        CGPoint next = [[points objectAtIndex:(i+1)] CGPointValue];
        
        for(int x=cur.x;x<(int)next.x;x++) 
        {
            double t = (double)(x-cur.x)/(next.x-cur.x);
            
            double a = 1-t;
            double b = t;
            double h = next.x-cur.x;
            
            double y= a*cur.y + b*next.y + (h*h/6)*( (a*a*a-a)*sd[i]+ (b*b*b-b)*sd[i+1] );
                        
            if (y > 255.0)
            {
                y = 255.0;   
            }
            else if (y < 0.0)
            {
                y = 0.0;   
            }
            
            [output addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
        }
    }
    
    // If the last point is (255, 255) it doesn't get added.
    if ([output count] == 255) {
        [output addObject:[points lastObject]];
    }
    return output;
}

- (NSMutableArray *)secondDerivative:(NSArray *)points
{
    int n = [points count];
    if ((n <= 0) || (n == 1))
    {
        return nil;
    }
    
    double matrix[n][3];
    double result[n];
    matrix[0][1]=1;
    // What about matrix[0][1] and matrix[0][0]? Assuming 0 for now (Brad L.)
    matrix[0][0]=0;    
    matrix[0][2]=0;    
    
    for(int i=1;i<n-1;i++) 
    {
        CGPoint P1 = [[points objectAtIndex:(i-1)] CGPointValue];
        CGPoint P2 = [[points objectAtIndex:i] CGPointValue];
        CGPoint P3 = [[points objectAtIndex:(i+1)] CGPointValue];
        
        matrix[i][0]=(double)(P2.x-P1.x)/6;
        matrix[i][1]=(double)(P3.x-P1.x)/3;
        matrix[i][2]=(double)(P3.x-P2.x)/6;
        result[i]=(double)(P3.y-P2.y)/(P3.x-P2.x) - (double)(P2.y-P1.y)/(P2.x-P1.x);
    }
    
    // What about result[0] and result[n-1]? Assuming 0 for now (Brad L.)
    result[0] = 0;
    result[n-1] = 0;
	
    matrix[n-1][1]=1;
    // What about matrix[n-1][0] and matrix[n-1][2]? For now, assuming they are 0 (Brad L.)
    matrix[n-1][0]=0;
    matrix[n-1][2]=0;
    
  	// solving pass1 (up->down)
  	for(int i=1;i<n;i++) 
    {
		double k = matrix[i][0]/matrix[i-1][1];
		matrix[i][1] -= k*matrix[i-1][2];
		matrix[i][0] = 0;
		result[i] -= k*result[i-1];
    }
	// solving pass2 (down->up)
	for(int i=n-2;i>=0;i--) 
    {
		double k = matrix[i][2]/matrix[i+1][1];
		matrix[i][1] -= k*matrix[i+1][0];
		matrix[i][2] = 0;
		result[i] -= k*result[i+1];
	}
    
    double y2[n];
    for(int i=0;i<n;i++) y2[i]=result[i]/matrix[i][1];
    
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:n];
    for (int i=0;i<n;i++) 
    {
        [output addObject:[NSNumber numberWithDouble:y2[i]]];
    }
    
    return output;
}

- (void)updateToneCurveTexture;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageOpenGLESContext useImageProcessingContext];
        if (!toneCurveTexture)
        {
            glActiveTexture(GL_TEXTURE3);
            glGenTextures(1, &toneCurveTexture);
            glBindTexture(GL_TEXTURE_2D, toneCurveTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            toneCurveByteArray = calloc(256 * 4, sizeof(GLubyte));
        }
        else
        {
            glActiveTexture(GL_TEXTURE3);
            glBindTexture(GL_TEXTURE_2D, toneCurveTexture);
        }
        
        if ( ([_redCurve count] >= 256) && ([_greenCurve count] >= 256) && ([_blueCurve count] >= 256) && ([_rgbCompositeCurve count] >= 256))
        {
            for (unsigned int currentCurveIndex = 0; currentCurveIndex < 256; currentCurveIndex++)
            {
                // BGRA for upload to texture
                toneCurveByteArray[currentCurveIndex * 4] = fmax(currentCurveIndex + [[_blueCurve objectAtIndex:currentCurveIndex] floatValue] + [[_rgbCompositeCurve objectAtIndex:currentCurveIndex] floatValue], 0);
                toneCurveByteArray[currentCurveIndex * 4 + 1] = fmax(currentCurveIndex + [[_greenCurve objectAtIndex:currentCurveIndex] floatValue] + [[_rgbCompositeCurve objectAtIndex:currentCurveIndex] floatValue], 0);
                toneCurveByteArray[currentCurveIndex * 4 + 2] = fmax(currentCurveIndex + [[_redCurve objectAtIndex:currentCurveIndex] floatValue] + [[_rgbCompositeCurve objectAtIndex:currentCurveIndex] floatValue], 0);
                toneCurveByteArray[currentCurveIndex * 4 + 3] = 255;
            }
            
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 256 /*width*/, 1 /*height*/, 0, GL_BGRA, GL_UNSIGNED_BYTE, toneCurveByteArray);
        }        
    });
}

#pragma mark -
#pragma mark Rendering

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    if (self.preventRendering)
    {
        return;
    }
    
    [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
    [self setFilterFBO];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
  	glActiveTexture(GL_TEXTURE2);
  	glBindTexture(GL_TEXTURE_2D, sourceTexture);
  	glUniform1i(filterInputTextureUniform, 2);	
    
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, toneCurveTexture);                
    glUniform1i(toneCurveTextureUniform, 3);	
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);    
}

#pragma mark -
#pragma mark Accessors

- (void)setRGBControlPoints:(NSArray *)points
{
    _redControlPoints = [points copy];
    _redCurve = [self getPreparedSplineCurve:_redControlPoints];

    _greenControlPoints = [points copy];
    _greenCurve = [self getPreparedSplineCurve:_greenControlPoints];

    _blueControlPoints = [points copy];
    _blueCurve = [self getPreparedSplineCurve:_blueControlPoints];
    
    [self updateToneCurveTexture];
}


- (void)setRgbCompositeControlPoints:(NSArray *)newValue
{
  _rgbCompositeControlPoints = [newValue copy];
  _rgbCompositeCurve = [self getPreparedSplineCurve:_rgbCompositeControlPoints];
  
  [self updateToneCurveTexture];
}


- (void)setRedControlPoints:(NSArray *)newValue;
{  
    _redControlPoints = [newValue copy];
    _redCurve = [self getPreparedSplineCurve:_redControlPoints];
    
    [self updateToneCurveTexture];
}


- (void)setGreenControlPoints:(NSArray *)newValue
{
    _greenControlPoints = [newValue copy];
    _greenCurve = [self getPreparedSplineCurve:_greenControlPoints];
    
    [self updateToneCurveTexture];
}


- (void)setBlueControlPoints:(NSArray *)newValue
{
    _blueControlPoints = [newValue copy];
    _blueCurve = [self getPreparedSplineCurve:_blueControlPoints];
    
    [self updateToneCurveTexture];
}

@end

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

- (id) initWithACVFileData:(NSData*)data;


unsigned short int16WithBytes(Byte* bytes);
@end

@implementation GPUImageACVFile

@synthesize rgbCompositeCurvePoints, redCurvePoints, greenCurvePoints, blueCurvePoints;

- (id) initWithACVFileData:(NSData *)data {
    self = [super init];
    if (self != nil)
    {
        if (data.length == 0)
        {
            NSLog(@"failed to init ACVFile with data:%@", data);
            
            return self;
        }
        
        Byte* rawBytes = (Byte*) [data bytes];
        version        = int16WithBytes(rawBytes);
        rawBytes+=2;
        
        totalCurves    = int16WithBytes(rawBytes);
        rawBytes+=2;
        
        NSMutableArray *curves = [NSMutableArray new];
        
        float pointRate = (1.0 / 255);
        // The following is the data for each curve specified by count above
        for (NSInteger x = 0; x<totalCurves; x++)
        {
            unsigned short pointCount = int16WithBytes(rawBytes);
            rawBytes+=2;
            
            NSMutableArray *points = [NSMutableArray new];
            // point count * 4
            // Curve points. Each curve point is a pair of short integers where
            // the first number is the output value (vertical coordinate on the
            // Curves dialog graph) and the second is the input value. All coordinates have range 0 to 255.
            for (NSInteger y = 0; y<pointCount; y++)
            {
                unsigned short y = int16WithBytes(rawBytes);
                rawBytes+=2;
                unsigned short x = int16WithBytes(rawBytes);
                rawBytes+=2;
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
                [points addObject:[NSValue valueWithCGSize:CGSizeMake(x * pointRate, y * pointRate)]];
#else
                [points addObject:[NSValue valueWithSize:CGSizeMake(x * pointRate, y * pointRate)]];
#endif
            }
            [curves addObject:points];
        }
        rgbCompositeCurvePoints = [curves objectAtIndex:0];
        redCurvePoints = [curves objectAtIndex:1];
        greenCurvePoints = [curves objectAtIndex:2];
        blueCurvePoints = [curves objectAtIndex:3];
    }
    return self;
}

unsigned short int16WithBytes(Byte* bytes) {
    uint16_t result;
    memcpy(&result, bytes, sizeof(result));
    return CFSwapInt16BigToHost(result);
}
@end

#pragma mark -
#pragma mark GPUImageToneCurveFilter Implementation

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
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
#else
NSString *const kGPUImageToneCurveFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D toneCurveTexture;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     float redCurveValue = texture2D(toneCurveTexture, vec2(textureColor.r, 0.0)).r;
     float greenCurveValue = texture2D(toneCurveTexture, vec2(textureColor.g, 0.0)).g;
     float blueCurveValue = texture2D(toneCurveTexture, vec2(textureColor.b, 0.0)).b;
     
     gl_FragColor = vec4(redCurveValue, greenCurveValue, blueCurveValue, textureColor.a);
 }
);
#endif

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
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    NSArray *defaultCurve = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)], [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)], nil];
#else
    NSArray *defaultCurve = [NSArray arrayWithObjects:[NSValue valueWithPoint:NSMakePoint(0.0, 0.0)], [NSValue valueWithPoint:NSMakePoint(0.5, 0.5)], [NSValue valueWithPoint:NSMakePoint(1.0, 1.0)], nil];
#endif
    [self setRgbCompositeControlPoints:defaultCurve];
    [self setRedControlPoints:defaultCurve];
    [self setGreenControlPoints:defaultCurve];
    [self setBlueControlPoints:defaultCurve];
    
    return self;
}

// This pulls in Adobe ACV curve files to specify the tone curve
- (id)initWithACVData:(NSData *)data {
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageToneCurveFragmentShaderString]))
    {
		return nil;
    }
    
    toneCurveTextureUniform = [filterProgram uniformIndex:@"toneCurveTexture"];
    
    GPUImageACVFile *curve = [[GPUImageACVFile alloc] initWithACVFileData:data];
    
    [self setRgbCompositeControlPoints:curve.rgbCompositeCurvePoints];
    [self setRedControlPoints:curve.redCurvePoints];
    [self setGreenControlPoints:curve.greenCurvePoints];
    [self setBlueControlPoints:curve.blueCurvePoints];
    
    curve = nil;
    
    return self;
}

- (id)initWithACV:(NSString*)curveFilename
{
    return [self initWithACVURL:[[NSBundle mainBundle] URLForResource:curveFilename
                                                        withExtension:@"acv"]];
}

- (id)initWithACVURL:(NSURL*)curveFileURL
{
    NSData* fileData = [NSData dataWithContentsOfURL:curveFileURL];
    return [self initWithACVData:fileData];
}

- (void)setPointsWithACV:(NSString*)curveFilename
{
    [self setPointsWithACVURL:[[NSBundle mainBundle] URLForResource:curveFilename withExtension:@"acv"]];
}

- (void)setPointsWithACVURL:(NSURL*)curveFileURL
{
    NSData* fileData = [NSData dataWithContentsOfURL:curveFileURL];
    GPUImageACVFile *curve = [[GPUImageACVFile alloc] initWithACVFileData:fileData];
    
    [self setRgbCompositeControlPoints:curve.rgbCompositeCurvePoints];
    [self setRedControlPoints:curve.redCurvePoints];
    [self setGreenControlPoints:curve.greenCurvePoints];
    [self setBlueControlPoints:curve.blueCurvePoints];
    
    curve = nil;
}

- (void)dealloc
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];

        if (toneCurveTexture)
        {
            glDeleteTextures(1, &toneCurveTexture);
            toneCurveTexture = 0;
            free(toneCurveByteArray);
        }
    });
}

#pragma mark -
#pragma mark Curve calculation

- (NSArray *)getPreparedSplineCurve:(NSArray *)points
{
    if (points && [points count] > 0) 
    {
        // Sort the array.
        NSArray *sortedPoints = [points sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            float x1 = [(NSValue *)a CGPointValue].x;
            float x2 = [(NSValue *)b CGPointValue].x;
#else
            float x1 = [(NSValue *)a pointValue].x;
            float x2 = [(NSValue *)b pointValue].x;
#endif
            return x1 > x2;
        }];
                
        // Convert from (0, 1) to (0, 255).
        NSMutableArray *convertedPoints = [NSMutableArray arrayWithCapacity:[sortedPoints count]];
        for (int i=0; i<[points count]; i++){
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            CGPoint point = [[sortedPoints objectAtIndex:i] CGPointValue];
#else
            NSPoint point = [[sortedPoints objectAtIndex:i] pointValue];
#endif
            point.x = point.x * 255;
            point.y = point.y * 255;
                        
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            [convertedPoints addObject:[NSValue valueWithCGPoint:point]];
#else
            [convertedPoints addObject:[NSValue valueWithPoint:point]];
#endif
        }
        
        
        NSMutableArray *splinePoints = [self splineCurve:convertedPoints];
        
        // If we have a first point like (0.3, 0) we'll be missing some points at the beginning
        // that should be 0.
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        CGPoint firstSplinePoint = [[splinePoints objectAtIndex:0] CGPointValue];
#else
        NSPoint firstSplinePoint = [[splinePoints objectAtIndex:0] pointValue];
#endif
        
        if (firstSplinePoint.x > 0) {
            for (int i=firstSplinePoint.x; i >= 0; i--) {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
                CGPoint newCGPoint = CGPointMake(i, 0);
                [splinePoints insertObject:[NSValue valueWithCGPoint:newCGPoint] atIndex:0];
#else
                NSPoint newNSPoint = NSMakePoint(i, 0);
                [splinePoints insertObject:[NSValue valueWithPoint:newNSPoint] atIndex:0];
#endif
            }
        }

        // Insert points similarly at the end, if necessary.
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        CGPoint lastSplinePoint = [[splinePoints lastObject] CGPointValue];

        if (lastSplinePoint.x < 255) {
            for (int i = lastSplinePoint.x + 1; i <= 255; i++) {
                CGPoint newCGPoint = CGPointMake(i, 255);
                [splinePoints addObject:[NSValue valueWithCGPoint:newCGPoint]];
            }
        }
#else
        NSPoint lastSplinePoint = [[splinePoints lastObject] pointValue];
        
        if (lastSplinePoint.x < 255) {
            for (int i = lastSplinePoint.x + 1; i <= 255; i++) {
                NSPoint newNSPoint = NSMakePoint(i, 255);
                [splinePoints addObject:[NSValue valueWithPoint:newNSPoint]];
            }
        }
#endif
        
        // Prepare the spline points.
        NSMutableArray *preparedSplinePoints = [NSMutableArray arrayWithCapacity:[splinePoints count]];
        for (int i=0; i<[splinePoints count]; i++) 
        {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            CGPoint newPoint = [[splinePoints objectAtIndex:i] CGPointValue];
#else
            NSPoint newPoint = [[splinePoints objectAtIndex:i] pointValue];
#endif
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
    
    // [points count] is equal to [sdA count]
    NSInteger n = [sdA count];
    if (n < 1)
    {
        return nil;
    }
    double sd[n];
    
    // From NSMutableArray to sd[n];
    for (int i=0; i<n; i++) 
    {
        sd[i] = [[sdA objectAtIndex:i] doubleValue];
    }
    
    
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:(n+1)];
                              
    for(int i=0; i<n-1 ; i++) 
    {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        CGPoint cur = [[points objectAtIndex:i] CGPointValue];
        CGPoint next = [[points objectAtIndex:(i+1)] CGPointValue];
#else
        NSPoint cur = [[points objectAtIndex:i] pointValue];
        NSPoint next = [[points objectAtIndex:(i+1)] pointValue];
#endif
        
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
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            [output addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
#else
            [output addObject:[NSValue valueWithPoint:NSMakePoint(x, y)]];
#endif
        }
    }
    
    // The above always misses the last point because the last point is the last next, so we approach but don't equal it.
    [output addObject:[points lastObject]];
    return output;
}

- (NSMutableArray *)secondDerivative:(NSArray *)points
{
    const NSInteger n = [points count];
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
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        CGPoint P1 = [[points objectAtIndex:(i-1)] CGPointValue];
        CGPoint P2 = [[points objectAtIndex:i] CGPointValue];
        CGPoint P3 = [[points objectAtIndex:(i+1)] CGPointValue];
#else
        NSPoint P1 = [[points objectAtIndex:(i-1)] pointValue];
        NSPoint P2 = [[points objectAtIndex:i] pointValue];
        NSPoint P3 = [[points objectAtIndex:(i+1)] pointValue];
#endif
        
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
	for(NSInteger i=n-2;i>=0;i--)
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
        [GPUImageContext useImageProcessingContext];
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
                GLubyte b = fmin(fmax(currentCurveIndex + [[_blueCurve objectAtIndex:currentCurveIndex] floatValue], 0), 255);
                toneCurveByteArray[currentCurveIndex * 4] = fmin(fmax(b + [[_rgbCompositeCurve objectAtIndex:b] floatValue], 0), 255);
                GLubyte g = fmin(fmax(currentCurveIndex + [[_greenCurve objectAtIndex:currentCurveIndex] floatValue], 0), 255);
                toneCurveByteArray[currentCurveIndex * 4 + 1] = fmin(fmax(g + [[_rgbCompositeCurve objectAtIndex:g] floatValue], 0), 255);
                GLubyte r = fmin(fmax(currentCurveIndex + [[_redCurve objectAtIndex:currentCurveIndex] floatValue], 0), 255);
                toneCurveByteArray[currentCurveIndex * 4 + 2] = fmin(fmax(r + [[_rgbCompositeCurve objectAtIndex:r] floatValue], 0), 255);
                toneCurveByteArray[currentCurveIndex * 4 + 3] = 255;
            }
            
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 256 /*width*/, 1 /*height*/, 0, GL_BGRA, GL_UNSIGNED_BYTE, toneCurveByteArray);
        }        
    });
}

#pragma mark -
#pragma mark Rendering

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    if (self.preventRendering)
    {
        [firstInputFramebuffer unlock];
        return;
    }
    
    [GPUImageContext setActiveShaderProgram:filterProgram];
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }

    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
  	glActiveTexture(GL_TEXTURE2);
  	glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
  	glUniform1i(filterInputTextureUniform, 2);	
    
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, toneCurveTexture);                
    glUniform1i(toneCurveTextureUniform, 3);	
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [firstInputFramebuffer unlock];
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
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

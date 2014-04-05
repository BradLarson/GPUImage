#import "GPUImageCrosshairGenerator.h"

NSString *const kGPUImageCrosshairVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 
 uniform float crosshairWidth;
 
 varying vec2 centerLocation;
 varying float pointSpacing;
 
 void main()
 {
     gl_Position = vec4(((position.xy * 2.0) - 1.0), 0.0, 1.0);
     gl_PointSize = crosshairWidth + 1.0;
     pointSpacing = 1.0 / crosshairWidth;
     centerLocation = vec2(pointSpacing * ceil(crosshairWidth / 2.0), pointSpacing * ceil(crosshairWidth / 2.0));
 }
);

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageCrosshairFragmentShaderString = SHADER_STRING
(
 uniform lowp vec3 crosshairColor;

 varying highp vec2 centerLocation;
 varying highp float pointSpacing;

 void main()
 {
     lowp vec2 distanceFromCenter = abs(centerLocation - gl_PointCoord.xy);
     lowp float axisTest = step(pointSpacing, gl_PointCoord.y) * step(distanceFromCenter.x, 0.09) + step(pointSpacing, gl_PointCoord.x) * step(distanceFromCenter.y, 0.09);

     gl_FragColor = vec4(crosshairColor * axisTest, axisTest);
//     gl_FragColor = vec4(distanceFromCenterInX, distanceFromCenterInY, 0.0, 1.0);
 }
);
#else
NSString *const kGPUImageCrosshairFragmentShaderString = SHADER_STRING
(
 GPUImageEscapedHashIdentifier(version 120)\n
 
 uniform vec3 crosshairColor;
 
 varying vec2 centerLocation;
 varying float pointSpacing;
 
 void main()
 {
     vec2 distanceFromCenter = abs(centerLocation - gl_PointCoord.xy);
     float axisTest = step(pointSpacing, gl_PointCoord.y) * step(distanceFromCenter.x, 0.09) + step(pointSpacing, gl_PointCoord.x) * step(distanceFromCenter.y, 0.09);
     
     gl_FragColor = vec4(crosshairColor * axisTest, axisTest);
     //     gl_FragColor = vec4(distanceFromCenterInX, distanceFromCenterInY, 0.0, 1.0);
 }
);
#endif

@implementation GPUImageCrosshairGenerator

@synthesize crosshairWidth = _crosshairWidth;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageCrosshairVertexShaderString fragmentShaderFromString:kGPUImageCrosshairFragmentShaderString]))
    {
        return nil;
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        crosshairWidthUniform = [filterProgram uniformIndex:@"crosshairWidth"];
        crosshairColorUniform = [filterProgram uniformIndex:@"crosshairColor"];
        
        self.crosshairWidth = 5.0;
        [self setCrosshairColorRed:0.0 green:1.0 blue:0.0];
    });
    
    return self;
}

#pragma mark -
#pragma mark Rendering

- (void)renderCrosshairsFromArray:(GLfloat *)crosshairCoordinates count:(NSUInteger)numberOfCrosshairs frameTime:(CMTime)frameTime;
{
    if (self.preventRendering)
    {
        return;
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:filterProgram];
        
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#else
        glEnable(GL_POINT_SPRITE);
        glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
#endif
        
        outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
        [outputFramebuffer activateFramebuffer];
        
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, crosshairCoordinates);
        
        glDrawArrays(GL_POINTS, 0, (GLsizei)numberOfCrosshairs);
        
        [self informTargetsAboutNewFrameAtTime:frameTime];
    });
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    // Prevent rendering of the frame by normal means
}

#pragma mark -
#pragma mark Accessors

- (void)setCrosshairWidth:(CGFloat)newValue;
{
    _crosshairWidth = newValue;
    
    [self setFloat:_crosshairWidth forUniform:crosshairWidthUniform program:filterProgram];
}

- (void)setCrosshairColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;
{
    GPUVector3 crosshairColor = {redComponent, greenComponent, blueComponent};
    
    [self setVec3:crosshairColor forUniform:crosshairColorUniform program:filterProgram];
}

@end

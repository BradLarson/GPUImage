#import "GPUImageLineGenerator.h"

NSString *const kGPUImageLineGeneratorVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 
 void main()
 {
     gl_Position = position;
 }
);

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageLineGeneratorFragmentShaderString = SHADER_STRING
(
 uniform lowp vec3 lineColor;
 
 void main()
 {
     gl_FragColor = vec4(lineColor, 1.0);
 }
);
#else
NSString *const kGPUImageLineGeneratorFragmentShaderString = SHADER_STRING
(
 uniform vec3 lineColor;
 
 void main()
 {
     gl_FragColor = vec4(lineColor, 1.0);
 }
);
#endif

@interface GPUImageLineGenerator()

- (void)generateLineCoordinates;

@end

@implementation GPUImageLineGenerator

@synthesize lineWidth = _lineWidth;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageLineGeneratorVertexShaderString fragmentShaderFromString:kGPUImageLineGeneratorFragmentShaderString]))
    {
        return nil;
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        lineWidthUniform = [filterProgram uniformIndex:@"lineWidth"];
        lineColorUniform = [filterProgram uniformIndex:@"lineColor"];
        
        self.lineWidth = 1.0;
        [self setLineColorRed:0.0 green:1.0 blue:0.0];
    });
    
    return self;
}

- (void)dealloc
{
    if (lineCoordinates)
    {
        free(lineCoordinates);
    }
}

#pragma mark -
#pragma mark Rendering

- (void)generateLineCoordinates;
{
    lineCoordinates = calloc(1024 * 4, sizeof(GLfloat));
}

- (void)renderLinesFromArray:(GLfloat *)lineSlopeAndIntercepts count:(NSUInteger)numberOfLines frameTime:(CMTime)frameTime;
{
    if (self.preventRendering)
    {
        return;
    }
    
    if (lineCoordinates == NULL)
    {
        [self generateLineCoordinates];
    }
    
    // Iterate through and generate vertices from the slopes and intercepts
    NSUInteger currentVertexIndex = 0;
    NSUInteger currentLineIndex = 0;
    NSUInteger maxLineIndex = numberOfLines *2;
    while(currentLineIndex < maxLineIndex)
    {
        GLfloat slope = lineSlopeAndIntercepts[currentLineIndex++];
        GLfloat intercept = lineSlopeAndIntercepts[currentLineIndex++];
        
        if (slope > 9000.0) // Vertical line
        {
            lineCoordinates[currentVertexIndex++] = intercept;
            lineCoordinates[currentVertexIndex++] = -1.0;
            lineCoordinates[currentVertexIndex++] = intercept;
            lineCoordinates[currentVertexIndex++] = 1.0;
        }
        else
        {
            lineCoordinates[currentVertexIndex++] = -1.0;
            lineCoordinates[currentVertexIndex++] = slope * -1.0 + intercept;
            lineCoordinates[currentVertexIndex++] = 1.0;
            lineCoordinates[currentVertexIndex++] = slope * 1.0 + intercept;
        }
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext setActiveShaderProgram:filterProgram];
        
        [self setFilterFBO];
        
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glBlendEquation(GL_FUNC_ADD);
        glBlendFunc(GL_ONE, GL_ONE);
        glEnable(GL_BLEND);
        
        glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, lineCoordinates);
        glDrawArrays(GL_LINES, 0, (numberOfLines * 2));
        
        glDisable(GL_BLEND);

        [self informTargetsAboutNewFrameAtTime:frameTime];
    });
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    // Prevent rendering of the frame by normal means
}

#pragma mark -
#pragma mark Accessors

- (void)setLineWidth:(CGFloat)newValue;
{
    _lineWidth = newValue;
    [GPUImageContext setActiveShaderProgram:filterProgram];
    glLineWidth(newValue);
}

- (void)setLineColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;
{
    GPUVector3 lineColor = {redComponent, greenComponent, blueComponent};
    
    [self setVec3:lineColor forUniform:lineColorUniform program:filterProgram];
}


@end

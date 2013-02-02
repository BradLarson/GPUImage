#import "GPUImageParallelCoordinateLineTransformFilter.h"

NSString *const kGPUImageHoughAccumulationVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 
 void main()
 {
     gl_Position = position;
 }
);

NSString *const kGPUImageHoughAccumulationFragmentShaderString = SHADER_STRING
(
 const lowp float scalingFactor = 1.0 / 256.0;
 
 void main()
 {
//     gl_FragColor = vec4(scalingFactor, scalingFactor, scalingFactor, 1.0);
     gl_FragColor = vec4(0.004, 0.004, 0.004, 1.0);
 }
);

@interface GPUImageParallelCoordinateLineTransformFilter()
// Rendering
- (void)generateLineCoordinates;

@end

@implementation GPUImageParallelCoordinateLineTransformFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageHoughAccumulationVertexShaderString fragmentShaderFromString:kGPUImageHoughAccumulationFragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

// TODO: have this be regenerated on change of image size
- (void)dealloc;
{
    free(rawImagePixels);
    free(lineCoordinates);
}

- (void)initializeAttributes;
{
    [filterProgram addAttribute:@"position"];
}

#pragma mark -
#pragma mark Rendering

#define MAXLINESCALINGFACTOR 4

- (void)generateLineCoordinates;
{
    unsigned int imageByteSize = inputTextureSize.width * inputTextureSize.height * 4;
    rawImagePixels = (GLubyte *)malloc(imageByteSize);

    maxLinePairsToRender = (inputTextureSize.width * inputTextureSize.height) / MAXLINESCALINGFACTOR;
    lineCoordinates = calloc(maxLinePairsToRender * 8, sizeof(GLfloat));
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    outputTextureRetainCount = [targets count];

    if (lineCoordinates == NULL)
    {
        [self generateLineCoordinates];
    }
    
    [self renderToTextureWithVertices:NULL textureCoordinates:NULL sourceTexture:filterSourceTexture];
    
    [self informTargetsAboutNewFrameAtTime:frameTime];
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    if (self.preventRendering)
    {
        return;
    }
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    
    // Grab the edge points from the previous frame and create the parallel coordinate lines for them
    // This would be a great place to have a working histogram pyramid implementation
    glFinish();
    glReadPixels(0, 0, inputTextureSize.width, inputTextureSize.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);
    
    CGFloat xAspectMultiplier = 1.0, yAspectMultiplier = 1.0;
    
//    if (inputTextureSize.width > inputTextureSize.height)
//    {
//        yAspectMultiplier = inputTextureSize.height / inputTextureSize.width;
//    }
//    else
//    {
//        xAspectMultiplier = inputTextureSize.width / inputTextureSize.height;
//    }
    
//    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    unsigned int imageByteSize = inputTextureSize.width * inputTextureSize.height * 4;
    unsigned int imageWidth = inputTextureSize.width * 4;
    
    linePairsToRender = 0;
    unsigned int currentByte = 0;
    unsigned int lineStorageIndex = 0;
    unsigned int maxLineStorageIndex = maxLinePairsToRender * 8 - 8;
    
    GLfloat minY = 100, maxY = -100, minX = 100, maxX = -100;
    while (currentByte < imageByteSize)
    {
        GLubyte colorByte = rawImagePixels[currentByte];        
        
        if (colorByte > 0)
        {
            unsigned int xCoordinate = currentByte % imageWidth;
            unsigned int yCoordinate = currentByte / imageWidth;
            
            CGFloat normalizedXCoordinate = (-1.0 + 2.0 * (CGFloat)(xCoordinate / 4) / inputTextureSize.width) * xAspectMultiplier;
            CGFloat normalizedYCoordinate = (-1.0 + 2.0 * (CGFloat)(yCoordinate) / inputTextureSize.height) * yAspectMultiplier;
            
            minY = MIN(minY, normalizedYCoordinate);
            maxY = MAX(maxY, normalizedYCoordinate);
            minX = MIN(minX, normalizedXCoordinate);
            maxX = MAX(maxX, normalizedXCoordinate);
            
//            NSLog(@"Parallel line coordinates: (%f, %f) - (%f, %f) - (%f, %f)", -1.0, -normalizedYCoordinate, 0.0, normalizedXCoordinate, 1.0, normalizedYCoordinate);
            // T space coordinates, (-d, -y) to (0, x)
            lineCoordinates[lineStorageIndex++] = -1.0;
            lineCoordinates[lineStorageIndex++] = -normalizedYCoordinate;
            lineCoordinates[lineStorageIndex++] = 0.0;
            lineCoordinates[lineStorageIndex++] = normalizedXCoordinate;

            // S space coordinates, (0, x) to (d, y)
            lineCoordinates[lineStorageIndex++] = 0.0;
            lineCoordinates[lineStorageIndex++] = normalizedXCoordinate;
            lineCoordinates[lineStorageIndex++] = 1.0;
            lineCoordinates[lineStorageIndex++] = normalizedYCoordinate;

            linePairsToRender++;
            
            linePairsToRender = MIN(linePairsToRender, maxLinePairsToRender);
            lineStorageIndex = MIN(lineStorageIndex, maxLineStorageIndex);
        }
        currentByte +=8;
    }
    
//    NSLog(@"Line pairs to render: %d out of max: %d", linePairsToRender, maxLinePairsToRender);
    
//    CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
//    NSLog(@"Line generation processing time : %f ms", 1000.0 * currentFrameTime);

    [self setFilterFBO];
    
    [GPUImageOpenGLESContext setActiveShaderProgram:filterProgram];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_ONE, GL_ONE);
    glEnable(GL_BLEND);
    
	glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, lineCoordinates);
    glDrawArrays(GL_LINES, 0, (linePairsToRender * 4));
    
    glDisable(GL_BLEND);
}

@end

#import "GPUImageHistogramFilter.h"

// Unlike other filters, this one uses a grid of GL_POINTs to sample the incoming image in a grid. A custom vertex shader reads the color in the texture at its position 
// and outputs a bin position in the final histogram as the vertex position. That point is then written into the image of the histogram using translucent pixels.
// The degree of translucency is controlled by the scalingFactor, which lets you adjust the dynamic range of the histogram. The histogram can only be generated for one
// color channel or luminance value at a time.
//
// This is based on this implementation: http://www.shaderwrangler.com/publications/histogram/histogram_cameraready.pdf
//
// Or at least that's how it would work if iOS could read from textures in a vertex shader, which it can't. Therefore, I read the texture data down from the
// incoming frame and process the texture colors as vertices.

NSString *const kGPUImageRedHistogramSamplingVertexShaderString = SHADER_STRING
(
 attribute vec4 position;

 void main()
 {
     gl_Position = vec4(-1.0 + (position.x * 0.0078125), 0.0, 0.0, 1.0);
     gl_PointSize = 1.0;
 }
);

//NSString *const kGPUImageGreenHistogramSamplingVertexShaderString = SHADER_STRING
//(
// attribute vec4 position;
// attribute vec4 inputTextureCoordinate;
// 
// void main()
// {
//     vec4 notUsed = texture2D(inputImageTexture, vec2(0.0, 0.0)); 
//     highp float colorAtThisVertex = texture2D(inputImageTexture, inputTextureCoordinate.uv).g;
//     gl_Position = vec4(-1.0 + 2.0 * colorAtThisVertex, 0.0, 0.0, 1.0);
// }
//);
//
//NSString *const kGPUImageBlueHistogramSamplingVertexShaderString = SHADER_STRING
//(
// attribute vec4 position;
// attribute vec4 inputTextureCoordinate;
// 
//// uniform sampler2D inputImageTexture;
// 
// void main()
// {
//     highp float colorAtThisVertex = texture2D(inputImageTexture, inputTextureCoordinate.uv).b;
//     gl_Position = vec4(-1.0 + 2.0 * colorAtThisVertex, 0.0, 0.0, 1.0);
// }
//);
//
//NSString *const kGPUImageLuminanceHistogramSamplingVertexShaderString = SHADER_STRING
//(
// attribute vec4 position;
// attribute vec4 inputTextureCoordinate;
// 
// uniform sampler2D inputImageTexture;
//
// const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);
// 
// void main()
// {
//     highp float luminance = dot(texture2D(inputImageTexture, inputTextureCoordinate.uv).rgb, W);
//     gl_Position = vec4(-1.0 + 2.0 * luminance, 0.0, 0.0, 1.0);
// }
//);

NSString *const kGPUImageHistogramAccumulationFragmentShaderString = SHADER_STRING
(
 uniform highp float scalingFactor;
 
 void main()
 {
     gl_FragColor = vec4(scalingFactor);
 }
);

@implementation GPUImageHistogramFilter

@synthesize samplingDensityInX = _samplingDensityInX;
@synthesize samplingDensityInY = _samplingDensityInY;
@synthesize scalingFactor = _scalingFactor;
@synthesize downsamplingFactor = _downsamplingFactor;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithHistogramType:(GPUImageHistogramType)newHistogramType;
{
    if (!(self = [super initWithVertexShaderFromString:kGPUImageRedHistogramSamplingVertexShaderString fragmentShaderFromString:kGPUImageHistogramAccumulationFragmentShaderString]))
    {
        return nil;
    }

    /*
    switch (newHistogramType)
    {
        case kGPUImageHistogramRed:
        {
            if (!(self = [super initWithVertexShaderFromString:kGPUImageRedHistogramSamplingVertexShaderString fragmentShaderFromString:kGPUImageHistogramAccumulationFragmentShaderString]))
            {
                return nil;
            }
        }; break;
        case kGPUImageHistogramGreen:
        {
            if (!(self = [super initWithVertexShaderFromString:kGPUImageGreenHistogramSamplingVertexShaderString fragmentShaderFromString:kGPUImageHistogramAccumulationFragmentShaderString]))
            {
                return nil;
            }
        }; break;
        case kGPUImageHistogramBlue:
        {
            if (!(self = [super initWithVertexShaderFromString:kGPUImageBlueHistogramSamplingVertexShaderString fragmentShaderFromString:kGPUImageHistogramAccumulationFragmentShaderString]))
            {
                return nil;
            }
        }; break;
        case kGPUImageHistogramLuminance:
        {
            if (!(self = [super initWithVertexShaderFromString:kGPUImageLuminanceHistogramSamplingVertexShaderString fragmentShaderFromString:kGPUImageHistogramAccumulationFragmentShaderString]))
            {
                return nil;
            }
        }; break;
    }
*/
    histogramType = newHistogramType;
    
    _samplingDensityInX = 3;
    _samplingDensityInY = 1;
    self.downsamplingFactor = 8;

    scalingFactorUniform = [filterProgram uniformIndex:@"scalingFactor"];
    self.scalingFactor = 0.004;

    return self;
}

- (void)dealloc;
{
    if (vertexSamplingCoordinates != NULL)
    {
        free(vertexSamplingCoordinates);
        free(textureSamplingCoordinates);
    }
}

#pragma mark -
#pragma mark Rendering

- (void)generatePointCoordinates;
{
    vertexSamplingCoordinates = calloc(inputTextureSize.width * inputTextureSize.height * 4, sizeof(GLubyte));
}

- (CGSize)sizeOfFBO;
{
    return CGSizeMake(256.0, 3.0);
}

- (void)newFrameReadyAtTime:(CMTime)frameTime;
{
    if (vertexSamplingCoordinates == NULL)
    {
        [self generatePointCoordinates];
    }
    
    [self renderToTextureWithVertices:vertexSamplingCoordinates textureCoordinates:textureSamplingCoordinates sourceTexture:filterSourceTexture];
    
    [self informTargetsAboutNewFrameAtTime:frameTime];
}

- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
{    
    for (id<GPUImageInput> currentTarget in targets)
    {
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            if ([GPUImageOpenGLESContext supportsFastTextureUpload] && preparedToCaptureImage)
            {
                NSInteger indexOfObject = [targets indexOfObject:currentTarget];
                [self setInputTextureForTarget:currentTarget atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
            }

            [currentTarget setInputSize:[self sizeOfFBO]];
            [currentTarget newFrameReadyAtTime:frameTime];
        }
    }
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    
    glReadPixels(0, 0, inputTextureSize.width, inputTextureSize.height, GL_RGBA, GL_UNSIGNED_BYTE, vertexSamplingCoordinates);

    [self setFilterFBO];
        
    [filterProgram use];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_ONE, GL_ONE);
    glEnable(GL_BLEND);
    
	glVertexAttribPointer(filterPositionAttribute, 4, GL_UNSIGNED_BYTE, 0, (_downsamplingFactor - 1) * 4, vertexSamplingCoordinates);
    glDrawArrays(GL_POINTS, 0, inputTextureSize.width * inputTextureSize.height / (CGFloat)_downsamplingFactor);

    glDisable(GL_BLEND);
}

#pragma mark -
#pragma mark Accessors

- (void)setScalingFactor:(CGFloat)newValue;
{
    _scalingFactor = newValue;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(scalingFactorUniform, _scalingFactor);
}

@end

#import "GPUImageHistogramFilter.h"

// Unlike other filters, this one uses a grid of GL_POINTs to sample the incoming image in a grid. A custom vertex shader reads the color in the texture at its position 
// and outputs a bin position in the final histogram as the vertex position. That point is then written into the image of the histogram using translucent pixels.
// The degree of translucency is controlled by the scalingFactor, which lets you adjust the dynamic range of the histogram. The histogram can only be generated for one
// color channel or luminance value at a time.

NSString *const kGPUImageRedHistogramSamplingVertexShaderString = SHADER_STRING
(
// attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform sampler2D inputImageTexture;

 void main()
 {
     float colorAtThisVertex = texture2D(inputImageTexture, inputTextureCoordinate.xy).x;
//     gl_Position = vec4(-1.0 + 2.0 * colorAtThisVertex, 0.0, 0.0, 1.0);
     gl_Position = vec4(colorAtThisVertex, 0.0, 0.0, 1.0);
//     gl_Position = vec4(inputTextureCoordinate.x, 0.0, 0.0, 1.0);
     gl_PointSize = 4.0;
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

// uniform sampler2D inputImageTexture;
 
 void main()
 {
//     lowp vec4 notUsed = texture2D(inputImageTexture, vec2(0.0, 0.0)); 

//     gl_FragColor = vec4(1.0, notUsed.r, 0.0, 1.0);
     gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
 }
 );

@implementation GPUImageHistogramFilter

@synthesize samplingDensityInX = _samplingDensityInX;
@synthesize samplingDensityInY = _samplingDensityInY;
@synthesize scalingFactor = _scalingFactor;

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

    scalingFactorUniform = [filterProgram uniformIndex:@"scalingFactor"];
    self.scalingFactor = 0.1;

    [self forceProcessingAtSize:CGSizeMake(256.0, 3.0)]; // Output just 256 pixels of color information for whatever bin 
    
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

//- (CGSize)sizeOfFBO;
//{
//    return CGSizeMake(256.0, 3.0);
//}

- (void)generatePointCoordinates;
{
    vertexSamplingCoordinates = calloc(_samplingDensityInX * _samplingDensityInY * 2, sizeof(GLfloat));
    textureSamplingCoordinates = calloc(_samplingDensityInX * _samplingDensityInY * 2, sizeof(GLfloat));
    
    GLfloat fractionalSpacingInX = 1.0 / (GLfloat)_samplingDensityInX;
    GLfloat fractionalSpacingInY = 1.0 / (GLfloat)_samplingDensityInY;
    
    for (NSUInteger currentYIndex = 0; currentYIndex < _samplingDensityInY; currentYIndex++)
    {
        GLfloat currentYTextureLocation = (GLfloat)currentYIndex * fractionalSpacingInY;
        GLfloat currentYVertexLocation = -1.0 + 2.0 * (GLfloat)currentYIndex * fractionalSpacingInY;
        
        for (NSUInteger currentXIndex = 0; currentXIndex < _samplingDensityInX; currentXIndex++)
        {
            GLfloat currentXTextureLocation = (GLfloat)currentXIndex * fractionalSpacingInX;
            NSInteger basePointerPosition = currentYIndex * _samplingDensityInX + currentXIndex;
            
            NSLog(@"Texture coord: %f, %f", currentXTextureLocation, currentYTextureLocation);
            textureSamplingCoordinates[basePointerPosition * 2] = currentXTextureLocation;
            textureSamplingCoordinates[(basePointerPosition * 2) + 1] = currentYTextureLocation;
            
            GLfloat currentXVertexLocation = -1.0 + 2.0 * (GLfloat)currentXIndex * fractionalSpacingInX;
            
            textureSamplingCoordinates[basePointerPosition * 2] = currentXVertexLocation;
            textureSamplingCoordinates[(basePointerPosition * 2) + 1] = currentYVertexLocation;            
        }
    }
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

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates sourceTexture:(GLuint)sourceTexture;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [self setFilterFBO];
        
    [filterProgram use];
    
    glClearColor(0.0, 0.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
//    glBlendEquation(GL_FUNC_ADD);
//    glBlendFunc(GL_ONE, GL_ONE);
//    glEnable(GL_BLEND);
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, sourceTexture);
    
    NSLog(@"Input texture uniform: %d", filterInputTextureUniform);
    NSLog(@"Texture attrib: %d, position attrib: %d", filterTextureCoordinateAttribute, filterPositionAttribute);
	
	glUniform1i(filterInputTextureUniform, 2);	
    
//    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
	glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    GLenum error = glGetError();
    NSLog(@"Error before: %d", error);
    glDrawArrays(GL_POINTS, 0, _samplingDensityInX * _samplingDensityInY);

    error = glGetError();
    NSLog(@"Error after: %d", error);
//    glDisable(GL_BLEND);
}

#pragma mark -
#pragma mark Accessors

- (void)setScalingFactor:(CGFloat)newValue;
{
//    _scalingFactor = newValue;
//    
//    [GPUImageOpenGLESContext useImageProcessingContext];
//    [filterProgram use];
//    glUniform1f(scalingFactorUniform, _scalingFactor);
}

@end

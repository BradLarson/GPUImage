#import "GPUImageRotationFilter.h"

NSString *const kGPUImageRotationFragmentShaderString =  SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);

@implementation GPUImageRotationFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithRotation:(GPUImageRotationMode)newRotationMode;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageRotationFragmentShaderString]))
    {
        return nil;
    }
    
    rotationMode = newRotationMode;

    return self;
}


#pragma mark -
#pragma mark GPUImageInput

- (void)setInputSize:(CGSize)newSize;
{
    CGSize processedSize = newSize;
    
    if ( (rotationMode == kGPUImageRotateLeft) || (rotationMode == kGPUImageRotateRight) )
    {
        processedSize.width = newSize.height;
        processedSize.height = newSize.width;
    }
    
    [super setInputSize:processedSize];
}

- (void)newFrameReadyAtTime:(CMTime)frameTime;
{
    static const GLfloat rotationSquareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };

    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };

    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };

    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };


    switch (rotationMode)
    {
        case kGPUImageRotateLeft: [self renderToTextureWithVertices:rotationSquareVertices textureCoordinates:rotateLeftTextureCoordinates sourceTexture:filterSourceTexture]; break;
        case kGPUImageRotateRight: [self renderToTextureWithVertices:rotationSquareVertices textureCoordinates:rotateRightTextureCoordinates sourceTexture:filterSourceTexture]; break;
        case kGPUImageFlipHorizonal: [self renderToTextureWithVertices:rotationSquareVertices textureCoordinates:verticalFlipTextureCoordinates sourceTexture:filterSourceTexture]; break;
        case kGPUImageFlipVertical: [self renderToTextureWithVertices:rotationSquareVertices textureCoordinates:horizontalFlipTextureCoordinates sourceTexture:filterSourceTexture]; break;
   		case kGPUImageRotateRightFlipVertical: [self renderToTextureWithVertices:rotationSquareVertices textureCoordinates:rotateRightVerticalFlipTextureCoordinates sourceTexture:filterSourceTexture]; break;
    }
    [self informTargetsAboutNewFrameAtTime:frameTime];
}

@end

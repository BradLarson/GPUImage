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
    if ( (rotationMode == kGPUImageRotateLeft) || (rotationMode == kGPUImageRotateRight) )
    {
        inputTextureSize.width = newSize.height;
        inputTextureSize.height = newSize.width;
    }
    else
    {
        inputTextureSize = newSize;
    }
}

- (void)newFrameReady;
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

    switch (rotationMode)
    {
        case kGPUImageRotateLeft: [self renderToTextureWithVertices:rotationSquareVertices textureCoordinates:rotateLeftTextureCoordinates]; break;
        case kGPUImageRotateRight: [self renderToTextureWithVertices:rotationSquareVertices textureCoordinates:rotateRightTextureCoordinates]; break;
        case kGPUImageFlipHorizonal: [self renderToTextureWithVertices:rotationSquareVertices textureCoordinates:verticalFlipTextureCoordinates]; break;
        case kGPUImageFlipVertical: [self renderToTextureWithVertices:rotationSquareVertices textureCoordinates:horizontalFlipTextureCoordinates]; break;
    }

}

@end

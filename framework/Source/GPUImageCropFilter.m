#import "GPUImageCropFilter.h"

NSString *const kGPUImageCropFragmentShaderString =  SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);

@implementation GPUImageCropFilter

@synthesize cropRegion = _cropRegion;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithCropRegion:(CGRect)newCropRegion;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageCropFragmentShaderString]))
    {
        return nil;
    }
    
    self.cropRegion = newCropRegion;

    return self;
}

- (id)init;
{
    if (!(self = [self initWithCropRegion:CGRectMake(0.0, 0.0, 1.0, 1.0)]))
    {
        return nil;
    }
    
    return self;
}

#pragma mark -
#pragma mark GPUImageInput

//- (void)setInputSize:(CGSize)newSize;
//{
//    CGSize croppedSize;
//    croppedSize.width = newSize.width * _cropRegion.size.width;
//    croppedSize.height = newSize.height * _cropRegion.size.height;
//    
//    inputTextureSize = croppedSize;
//}
//
- (void)newFrameReadyAtTime:(CMTime)frameTime;
{
    static const GLfloat cropSquareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    GLfloat cropTextureCoordinates[] = {
        _cropRegion.origin.x, _cropRegion.origin.y,
        CGRectGetMaxX(_cropRegion), _cropRegion.origin.y,
        _cropRegion.origin.x, CGRectGetMaxY(_cropRegion),
        CGRectGetMaxX(_cropRegion), CGRectGetMaxY(_cropRegion),
    };

    [self renderToTextureWithVertices:cropSquareVertices textureCoordinates:cropTextureCoordinates sourceTexture:filterSourceTexture];

    [self informTargetsAboutNewFrameAtTime:frameTime];
}

@end

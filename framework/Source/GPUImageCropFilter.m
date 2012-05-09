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

@interface GPUImageCropFilter ()

- (void)calculateCropTextureCoordinates;

@end

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
#pragma mark Rendering

- (CGSize)outputFrameSize;
{
    CGSize adjustedSize;
    
    if (GPUImageRotationSwapsWidthAndHeight(inputRotation))
    {
        adjustedSize.width = inputTextureSize.height * _cropRegion.size.width;
        adjustedSize.height = inputTextureSize.width * _cropRegion.size.height;
    }
    else
    {
        adjustedSize.width = inputTextureSize.width * _cropRegion.size.width;
        adjustedSize.height = inputTextureSize.height * _cropRegion.size.height;
    }
    
    return adjustedSize;
}

#pragma mark -
#pragma mark GPUImageInput

- (void)calculateCropTextureCoordinates;
{
    CGFloat minX = _cropRegion.origin.x;
    CGFloat minY = _cropRegion.origin.y;
    CGFloat maxX = CGRectGetMaxX(_cropRegion);
    CGFloat maxY = CGRectGetMaxY(_cropRegion);
    
    switch(inputRotation)
    {
        case kGPUImageNoRotation:
        {
            cropTextureCoordinates[0] = minX; // 0,0
            cropTextureCoordinates[1] = minY;
            
            cropTextureCoordinates[2] = maxX; // 1,0
            cropTextureCoordinates[3] = minY;

            cropTextureCoordinates[4] = minX; // 0,1
            cropTextureCoordinates[5] = maxY;

            cropTextureCoordinates[4] = maxX; // 1,1
            cropTextureCoordinates[5] = maxY;
        }; break;
        case kGPUImageRotateLeft:
        {
            cropTextureCoordinates[0] = maxX; // 1,0
            cropTextureCoordinates[1] = minY;

            cropTextureCoordinates[2] = maxX; // 1,1
            cropTextureCoordinates[3] = maxY;
            
            cropTextureCoordinates[4] = minX; // 0,0
            cropTextureCoordinates[5] = minY;
            
            cropTextureCoordinates[6] = minX; // 0,1
            cropTextureCoordinates[7] = maxY;
        }; break;
        case kGPUImageRotateRight: 
        {
            cropTextureCoordinates[0] = minX; // 0,1
            cropTextureCoordinates[1] = maxY;

            cropTextureCoordinates[2] = minX; // 0,0
            cropTextureCoordinates[3] = minY;
            
            cropTextureCoordinates[4] = maxX; // 1,1
            cropTextureCoordinates[5] = maxY;

            cropTextureCoordinates[6] = maxX; // 1,0
            cropTextureCoordinates[7] = minY;
        }; break;
        case kGPUImageFlipVertical:
        {
            cropTextureCoordinates[0] = minX; // 0,1
            cropTextureCoordinates[1] = maxY;

            cropTextureCoordinates[2] = maxX; // 1,1
            cropTextureCoordinates[3] = maxY;

            cropTextureCoordinates[4] = minX; // 0,0
            cropTextureCoordinates[5] = minY;
            
            cropTextureCoordinates[6] = maxX; // 1,0
            cropTextureCoordinates[7] = minY;
        }; break;
        case kGPUImageFlipHorizonal:
        {
            cropTextureCoordinates[0] = maxX; // 1,0
            cropTextureCoordinates[1] = minY;

            cropTextureCoordinates[2] = minX; // 0,0
            cropTextureCoordinates[3] = minY;
            
            cropTextureCoordinates[4] = maxX; // 1,1
            cropTextureCoordinates[5] = maxY;
            
            cropTextureCoordinates[6] = minX; // 0,1
            cropTextureCoordinates[7] = maxY;
        }; break;
        case kGPUImageRotateRightFlipVertical:
        {
            cropTextureCoordinates[0] = minX; // 0,0
            cropTextureCoordinates[1] = minY;
            
            cropTextureCoordinates[2] = minX; // 0,1
            cropTextureCoordinates[3] = maxY;

            cropTextureCoordinates[4] = maxX; // 1,0
            cropTextureCoordinates[5] = minY;
            
            cropTextureCoordinates[6] = maxX; // 1,1
            cropTextureCoordinates[7] = maxY;
        }; break;
    }
}

- (void)newFrameReadyAtTime:(CMTime)frameTime;
{
    static const GLfloat cropSquareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    [self renderToTextureWithVertices:cropSquareVertices textureCoordinates:cropTextureCoordinates sourceTexture:filterSourceTexture];

    [self informTargetsAboutNewFrameAtTime:frameTime];
}

#pragma mark -
#pragma mark Accessors

- (void)setCropRegion:(CGRect)newValue;
{
    _cropRegion = newValue;
    [self calculateCropTextureCoordinates];
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    [super setInputRotation:newInputRotation atIndex:textureIndex];
    [self calculateCropTextureCoordinates];
}

@end

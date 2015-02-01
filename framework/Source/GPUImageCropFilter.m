#import "GPUImageCropFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageCropFragmentShaderString =  SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);
#else
NSString *const kGPUImageCropFragmentShaderString =  SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);
#endif

@interface GPUImageCropFilter ()

- (void)calculateCropTextureCoordinates;

@end

@interface GPUImageCropFilter()
{
    CGSize originallySuppliedInputSize;
}

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

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    if (self.preventRendering)
    {
        return;
    }
    
//    if (overrideInputSize)
//    {
//        if (CGSizeEqualToSize(forcedMaximumSize, CGSizeZero))
//        {
//            return;
//        }
//        else
//        {
//            CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(newSize, CGRectMake(0.0, 0.0, forcedMaximumSize.width, forcedMaximumSize.height));
//            inputTextureSize = insetRect.size;
//            return;
//        }
//    }
    
    CGSize rotatedSize = [self rotatedSize:newSize forIndex:textureIndex];
    originallySuppliedInputSize = rotatedSize;

    CGSize scaledSize;
    scaledSize.width = rotatedSize.width * _cropRegion.size.width;
    scaledSize.height = rotatedSize.height * _cropRegion.size.height;

    
    if (CGSizeEqualToSize(scaledSize, CGSizeZero))
    {
        inputTextureSize = scaledSize;
    }
    else if (!CGSizeEqualToSize(inputTextureSize, scaledSize))
    {
        inputTextureSize = scaledSize;
    }
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
        case kGPUImageNoRotation: // Works
        {
            cropTextureCoordinates[0] = minX; // 0,0
            cropTextureCoordinates[1] = minY;
            
            cropTextureCoordinates[2] = maxX; // 1,0
            cropTextureCoordinates[3] = minY;

            cropTextureCoordinates[4] = minX; // 0,1
            cropTextureCoordinates[5] = maxY;

            cropTextureCoordinates[6] = maxX; // 1,1
            cropTextureCoordinates[7] = maxY;
        }; break;
        case kGPUImageRotateLeft: // Fixed
        {
            cropTextureCoordinates[0] = maxY; // 1,0
            cropTextureCoordinates[1] = 1.0 - maxX;

            cropTextureCoordinates[2] = maxY; // 1,1
            cropTextureCoordinates[3] = 1.0 - minX;

            cropTextureCoordinates[4] = minY; // 0,0
            cropTextureCoordinates[5] = 1.0 - maxX;

            cropTextureCoordinates[6] = minY; // 0,1
            cropTextureCoordinates[7] = 1.0 - minX;
        }; break;
        case kGPUImageRotateRight: // Fixed
        {
            cropTextureCoordinates[0] = minY; // 0,1
            cropTextureCoordinates[1] = 1.0 - minX;

            cropTextureCoordinates[2] = minY; // 0,0
            cropTextureCoordinates[3] = 1.0 - maxX;
            
            cropTextureCoordinates[4] = maxY; // 1,1
            cropTextureCoordinates[5] = 1.0 - minX;

            cropTextureCoordinates[6] = maxY; // 1,0
            cropTextureCoordinates[7] = 1.0 - maxX;
        }; break;
        case kGPUImageFlipVertical: // Works for me
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
        case kGPUImageFlipHorizonal: // Works for me
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
        case kGPUImageRotate180: // Fixed
        {
            cropTextureCoordinates[0] = maxX; // 1,1
            cropTextureCoordinates[1] = maxY;

            cropTextureCoordinates[2] = minX; // 0,1
            cropTextureCoordinates[3] = maxY;

            cropTextureCoordinates[4] = maxX; // 1,0
            cropTextureCoordinates[5] = minY;

            cropTextureCoordinates[6] = minX; // 0,0
            cropTextureCoordinates[7] = minY;
        }; break;
        case kGPUImageRotateRightFlipVertical: // Fixed
        {
            cropTextureCoordinates[0] = minY; // 0,0
            cropTextureCoordinates[1] = 1.0 - maxX;
            
            cropTextureCoordinates[2] = minY; // 0,1
            cropTextureCoordinates[3] = 1.0 - minX;

            cropTextureCoordinates[4] = maxY; // 1,0
            cropTextureCoordinates[5] = 1.0 - maxX;
            
            cropTextureCoordinates[6] = maxY; // 1,1
            cropTextureCoordinates[7] = 1.0 - minX;
        }; break;
        case kGPUImageRotateRightFlipHorizontal: // Fixed
        {
            cropTextureCoordinates[0] = maxY; // 1,1
            cropTextureCoordinates[1] = 1.0 - minX;

            cropTextureCoordinates[2] = maxY; // 1,0
            cropTextureCoordinates[3] = 1.0 - maxX;

            cropTextureCoordinates[4] = minY; // 0,1
            cropTextureCoordinates[5] = 1.0 - minX;

            cropTextureCoordinates[6] = minY; // 0,0
            cropTextureCoordinates[7] = 1.0 - maxX;
        }; break;
    }
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    static const GLfloat cropSquareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    [self renderToTextureWithVertices:cropSquareVertices textureCoordinates:cropTextureCoordinates];

    [self informTargetsAboutNewFrameAtTime:frameTime];
}

#pragma mark -
#pragma mark Accessors

- (void)setCropRegion:(CGRect)newValue;
{
    NSParameterAssert(newValue.origin.x >= 0 && newValue.origin.x <= 1 &&
                      newValue.origin.y >= 0 && newValue.origin.y <= 1 &&
                      newValue.size.width >= 0 && newValue.size.width <= 1 &&
                      newValue.size.height >= 0 && newValue.size.height <= 1);

    _cropRegion = newValue;
    [self calculateCropTextureCoordinates];
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    [super setInputRotation:newInputRotation atIndex:textureIndex];
    [self calculateCropTextureCoordinates];
}

@end

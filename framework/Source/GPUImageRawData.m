#import "GPUImageRawData.h"

@interface GPUImageRawData ()
{
    CGSize imageSize;
    BOOL hasReadFromTheCurrentFrame;
}
@end

@implementation GPUImageRawData

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithImageSize:(CGSize)newImageSize;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    imageSize = newImageSize;

    hasReadFromTheCurrentFrame = NO;
    _rawBytesForImage = NULL;

    return self;
}

- (void)dealloc
{
    if (_rawBytesForImage != NULL)
    {
        free(_rawBytesForImage);
        _rawBytesForImage = NULL;
    }
}

#pragma mark -
#pragma mark Data access

- (GPUByteColorVector)colorAtLocation:(CGPoint)locationInImage;
{
    GPUByteColorVector *imageColorBytes = (GPUByteColorVector *)self.rawBytesForImage;
    
    CGPoint locationToPickFrom = CGPointZero;
    locationToPickFrom.x = MIN(MAX(locationInImage.x, 0.0), (imageSize.width - 1.0));
    locationToPickFrom.y = MIN(MAX(locationInImage.y, 0.0), (imageSize.height - 1.0));
    
    return imageColorBytes[(int)(round(locationToPickFrom.x * locationToPickFrom.y))];
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReady;
{
    hasReadFromTheCurrentFrame = NO;

    [self.delegate newImageFrameAvailableFromDataSource:self];
}

- (void)setInputTexture:(GLuint)newInputTexture;
{
    _openGLTexture = newInputTexture;
}

- (void)setInputSize:(CGSize)newSize;
{
    
}

- (CGSize)maximumOutputSize;
{
    return imageSize;
}

#pragma mark -
#pragma mark Accessors

@synthesize rawBytesForImage = _rawBytesForImage;
@synthesize openGLTexture = _openGLTexture;
@synthesize delegate = _delegate;

- (GLubyte *)rawBytesForImage;
{
    if (_rawBytesForImage == NULL)
    {
        _rawBytesForImage = (GLubyte *) calloc(imageSize.width * imageSize.height * 4, sizeof(GLubyte));
        hasReadFromTheCurrentFrame = NO;
    }
    
    if (hasReadFromTheCurrentFrame)
    {
        return _rawBytesForImage;
    }
    else
    {
        [GPUImageOpenGLESContext useImageProcessingContext];
        // This might require a re-rendering of the previous frame in order for the reading of the pixels to work
        glReadPixels(0, 0, imageSize.width, imageSize.height, GL_RGBA, GL_UNSIGNED_BYTE, _rawBytesForImage);

        return _rawBytesForImage;
    }
    
}

@end

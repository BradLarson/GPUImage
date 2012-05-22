#import "GPUImageRawDataInput.h"

@interface GPUImageRawDataInput()
- (void)uploadBytes:(GLubyte *)bytesToUpload;
@end

@implementation GPUImageRawDataInput

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    uploadedImageSize = imageSize;
        
    [self uploadBytes:bytesToUpload];
    
    return self;
}

#pragma mark -
#pragma mark Image rendering

- (void)uploadBytes:(GLubyte *)bytesToUpload;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    
    glBindTexture(GL_TEXTURE_2D, outputTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)uploadedImageSize.width, (int)uploadedImageSize.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, bytesToUpload);
}

- (void)updateDataFromBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize;
{
    uploadedImageSize = imageSize;

    [self uploadBytes:bytesToUpload];
}

- (void)processData;
{
    CGSize pixelSizeOfImage = [self outputImageSize];
    
    for (id<GPUImageInput> currentTarget in targets)
    {
        NSInteger indexOfObject = [targets indexOfObject:currentTarget];
        NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
        
        [currentTarget setInputSize:pixelSizeOfImage atIndex:textureIndexOfTarget];
        [currentTarget newFrameReadyAtTime:kCMTimeInvalid];
    }    
}

- (CGSize)outputImageSize;
{
    return uploadedImageSize;
}

@end

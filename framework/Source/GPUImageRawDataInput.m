#import "GPUImageRawDataInput.h"

@interface GPUImageRawDataInput()
- (void)uploadBytes:(GLubyte *)bytesToUpload;
@end

@implementation GPUImageRawDataInput

@synthesize pixelFormat = _pixelFormat;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize;
{
    if (!(self = [self initWithBytes:bytesToUpload size:imageSize pixelFormat:GPUPixelFormatBGRA]))
    {
		return nil;
    }
	
	return self;
}

- (id)initWithBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize pixelFormat:(GPUPixelFormat)pixelFormat;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
	dataUpdateSemaphore = dispatch_semaphore_create(1);

    uploadedImageSize = imageSize;
	self.pixelFormat = pixelFormat;
        
    [self uploadBytes:bytesToUpload];
    
    return self;
}

- (void)dealloc;
{
    if (dataUpdateSemaphore != NULL)
    {
        dispatch_release(dataUpdateSemaphore);
    }
}

#pragma mark -
#pragma mark Image rendering

- (void)uploadBytes:(GLubyte *)bytesToUpload;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    
	[self initializeOutputTextureIfNeeded];

    glBindTexture(GL_TEXTURE_2D, outputTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)uploadedImageSize.width, (int)uploadedImageSize.height, 0, (GLint)_pixelFormat, GL_UNSIGNED_BYTE, bytesToUpload);
}

- (void)updateDataFromBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize;
{
    uploadedImageSize = imageSize;

    [self uploadBytes:bytesToUpload];
}

- (void)processData;
{
	if (dispatch_semaphore_wait(dataUpdateSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return;
    }
	
	runAsynchronouslyOnVideoProcessingQueue(^{

		CGSize pixelSizeOfImage = [self outputImageSize];
    
		for (id<GPUImageInput> currentTarget in targets)
		{
			NSInteger indexOfObject = [targets indexOfObject:currentTarget];
			NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
        
			[currentTarget setInputSize:pixelSizeOfImage atIndex:textureIndexOfTarget];
			[currentTarget newFrameReadyAtTime:kCMTimeInvalid atIndex:textureIndexOfTarget];
		}
	
		dispatch_semaphore_signal(dataUpdateSemaphore);
	});
}

- (CGSize)outputImageSize;
{
    return uploadedImageSize;
}

@end

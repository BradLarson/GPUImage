#import "GPUImageOutput.h"

// The bytes passed into this input are not copied or retained, but you are free to deallocate them after they are used by this filter.
// The bytes are uploaded and stored within a texture, so nothing is kept locally.
// The default format for input bytes is GPUPixelFormatBGRA, unless specified with pixelFormat:

typedef enum {
	GPUPixelFormatBGRA = GL_BGRA,
	GPUPixelFormatRGBA = GL_RGBA
} GPUPixelFormat;

@interface GPUImageRawDataInput : GPUImageOutput
{
    CGSize uploadedImageSize;
	
	dispatch_semaphore_t dataUpdateSemaphore;
}

// Initialization and teardown
- (id)initWithBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize;
- (id)initWithBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize pixelFormat:(GPUPixelFormat)pixelFormat;

/** Input data pixel format
 */
@property (readwrite, nonatomic) GPUPixelFormat pixelFormat;

// Image rendering
- (void)updateDataFromBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize;
- (void)processData;
- (CGSize)outputImageSize;

@end

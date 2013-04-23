#import <Cocoa/Cocoa.h>
#import "GPUImageOutput.h"

@interface GPUImagePicture : GPUImageOutput
{
    CGSize pixelSizeOfImage;
    BOOL hasProcessedImage;
    
    dispatch_semaphore_t imageUpdateSemaphore;
}

// Initialization and teardown
- (id)initWithURL:(NSURL *)url;
- (id)initWithImage:(NSImage *)newImageSource;
- (id)initWithCGImage:(CGImageRef)newImageSource;
- (id)initWithImage:(NSImage *)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;
- (id)initWithCGImage:(CGImageRef)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;

// Image rendering
- (void)processImage;
- (CGSize)outputImageSize;

@end

#import <UIKit/UIKit.h>
#import "GPUImageOutput.h"


@interface GPUImagePicture : GPUImageOutput
{
    CGSize pixelSizeOfImage;
}

// Initialization and teardown
- (id)initWithImage:(UIImage *)newImageSource;
- (id)initWithImage:(UIImage *)newImageSource smoothlyScaleOutput:(BOOL)smoothlyScaleOutput;

// Image rendering
- (void)processImage;
- (CGSize)outputImageSize;

@end

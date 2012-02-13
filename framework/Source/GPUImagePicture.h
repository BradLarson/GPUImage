#import <UIKit/UIKit.h>
#import "GPUImageOutput.h"


@interface GPUImagePicture : GPUImageOutput
{
    UIImage *imageSource;
}

// Initialization and teardown
- (id)initWithImage:(UIImage *)newImageSource;

// Image rendering
- (void)processImage;

@end

#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleImageViewController : UIViewController
{
    GPUImagePicture *sourcePicture;
    GPUImageFilter *sepiaFilter, *sepiaFilter2;
    GPUImageCrosshairGenerator *crosshairGenerator;
    GPUImageAlphaBlendFilter *blendFilter;
}

// Image filtering
- (void)setupDisplayFiltering;
- (void)setupImageFilteringToDisk;

@end

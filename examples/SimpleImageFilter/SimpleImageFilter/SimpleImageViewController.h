#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleImageViewController : UIViewController
{
    GPUImagePicture *sourcePicture;
    GPUImageFilter *sepiaFilter, *sepiaFilter2;
}

// Image filtering
- (void)setupDisplayFiltering;
- (void)setupImageFilteringToDisk;

@end

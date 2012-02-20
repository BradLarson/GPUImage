#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleVideoFileFilterViewController : UIViewController
{
    GPUImageFile *imageFile;
    GPUImagePixellateFilter *pixellateFilter;
}

- (IBAction)updatePixelWidth:(id)sender;

@end

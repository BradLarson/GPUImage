#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleVideoFileFilterViewController : UIViewController
{
    GPUImageMovie *imageFile;
    GPUImagePixellateFilter *pixellateFilter;
}

- (IBAction)updatePixelWidth:(id)sender;

@end

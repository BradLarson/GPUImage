#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleVideoFilterViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImagePixellateFilter *pixellateFilter;
}

- (IBAction)updatePixelWidth:(id)sender;

@end

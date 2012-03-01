#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleVideoFilterViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImageFilter *filter;
    GPUImageMovieWriter *movieWriter;
}

- (IBAction)updatePixelWidth:(id)sender;

@end

#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleVideoFileFilterViewController : UIViewController
{
    GPUImageMovie *movieFile;
    GPUImagePixellateFilter *pixellateFilter;
    GPUImageMovieWriter *movieWriter;
}

- (IBAction)updatePixelWidth:(id)sender;

@end

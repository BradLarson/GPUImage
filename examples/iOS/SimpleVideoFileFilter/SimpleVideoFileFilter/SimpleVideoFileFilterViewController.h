#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleVideoFileFilterViewController : UIViewController
{
    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
    NSTimer * timer;
}

@property (retain, nonatomic) IBOutlet UILabel *progressLabel;
- (IBAction)updatePixelWidth:(id)sender;

@end
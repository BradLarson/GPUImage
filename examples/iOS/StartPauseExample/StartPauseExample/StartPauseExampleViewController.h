#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface StartPauseExampleViewController : UIViewController
{
    NSURL *movieURL;
    
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
}

- (IBAction)updateSliderValue:(id)sender;
- (IBAction)switchFilter:(UIButton *)sender;
- (IBAction)switchRecord:(UIButton *)sender;
- (IBAction)stopRecord:(UIButton *)sender;

@end

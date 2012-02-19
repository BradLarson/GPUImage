#import <UIKit/UIKit.h>
#import "GPUImage.h"

typedef enum { GPUIMAGE_SEPIA, GPUIMAGE_PIXELLATE, GPUIMAGE_SATURATION} GPUImageShowcaseFilterType;
 

@interface ShowcaseFilterViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImageFilter *filter;
    GPUImageShowcaseFilterType filterType;
    
    __unsafe_unretained UISlider *_filterSettingsSlider;
}

@property(readwrite, unsafe_unretained, nonatomic) IBOutlet UISlider *filterSettingsSlider;

// Initialization and teardown
- (id)initWithFilterType:(GPUImageShowcaseFilterType)newFilterType;
- (void)setupFilter;

// Filter adjustments
- (IBAction)updateFilterFromSlider:(id)sender;

@end

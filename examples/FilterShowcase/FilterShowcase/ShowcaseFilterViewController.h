#import <UIKit/UIKit.h>
#import "GPUImage.h"

typedef enum { GPUIMAGE_SATURATION, GPUIMAGE_CONTRAST, GPUIMAGE_BRIGHTNESS, GPUIMAGE_GAMMA, GPUIMAGE_SEPIA, GPUIMAGE_COLORINVERT, GPUIMAGE_PIXELLATE, GPUIMAGE_SOBELEDGEDETECTION, GPUIMAGE_TOON, GPUIMAGE_KUWAHARA, GPUIMAGE_DISSOLVE, GPUIMAGE_MULTIPLY, GPUIMAGE_OVERLAY, GPUIMAGE_LIGHTEN, GPUIMAGE_DARKEN, GPUIMAGE_CUSTOM, GPUIMAGE_NUMFILTERS} GPUImageShowcaseFilterType; 

@interface ShowcaseFilterViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImageFilter *filter;
    GPUImagePicture *sourcePicture;
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

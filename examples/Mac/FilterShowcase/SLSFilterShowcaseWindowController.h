#import <Cocoa/Cocoa.h>
#import <GPUImage/GPUImage.h>

typedef enum {
    GPUIMAGE_SATURATION,
    GPUIMAGE_CONTRAST,
    GPUIMAGE_BRIGHTNESS,
    GPUIMAGE_LEVELS,
    GPUIMAGE_EXPOSURE,
    GPUIMAGE_RGB,
    GPUIMAGE_HUE,
    GPUIMAGE_WHITEBALANCE,
    GPUIMAGE_MONOCHROME,
    GPUIMAGE_PIXELLATE,
    GPUIMAGE_GRAYSCALE,
    GPUIMAGE_SOBELEDGEDETECTION,
    GPUIMAGE_SKETCH,
    GPUIMAGE_TOON,
    GPUIMAGE_KUWAHARA,
    GPUIMAGE_GAUSSIANBLUR,
    GPUIMAGE_BILATERAL,
    GPUIMAGE_NUMFILTERS
} GPUImageShowcaseFilterType;

@interface SLSFilterShowcaseWindowController : NSWindowController
{
    GPUImageOutput<GPUImageInput> *currentlySelectedFilter;
    GPUImageAVCamera *inputCamera;
    NSUInteger currentlySelectedRow;
}

@property(readwrite) IBOutlet GPUImageView *glView;
@property(readwrite) BOOL enableSlider;
@property(readwrite, nonatomic) CGFloat minimumSliderValue, maximumSliderValue, currentSliderValue;

- (void)changeSelectedRow:(NSUInteger)newRowIndex;

@end

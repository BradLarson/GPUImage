#import <Cocoa/Cocoa.h>
#import <GPUImage/GPUImage.h>

typedef enum {
    GPUIMAGE_BRIGHTNESS,
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

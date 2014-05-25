#import <Cocoa/Cocoa.h>
#import <GPUImage/GPUImage.h>

@interface SLSFilterShowcaseWindowController : NSWindowController

@property (readwrite) IBOutlet GPUImageView *glView;
@property (readwrite) BOOL enableSlider;
@property (readwrite, nonatomic) CGFloat minimumSliderValue;
@property (readwrite, nonatomic) CGFloat maximumSliderValue;
@property (readwrite, nonatomic) CGFloat currentSliderValue;
@property (readwrite, nonatomic) NSUInteger selectedRow;

@property (readwrite, nonatomic) NSArray *imageFilterClassNames;

@end

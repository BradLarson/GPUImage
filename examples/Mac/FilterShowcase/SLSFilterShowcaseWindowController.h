#import <Cocoa/Cocoa.h>
#import <GPUImage/GPUImage.h>

@interface SLSFilterShowcaseWindowController : NSWindowController

@property (nonatomic, strong) IBOutlet GPUImageView *glView;

@property (nonatomic) BOOL enableSlider;
@property (nonatomic) CGFloat minimumSliderValue;
@property (nonatomic) CGFloat maximumSliderValue;
@property (nonatomic) CGFloat currentSliderValue;

@property (nonatomic, strong) NSArray *imageFilterClassNames;
@property (nonatomic, strong) NSArray *filterVariables;
@property (nonatomic) NSUInteger selectedRow;
@property (nonatomic) NSUInteger selectedVariableIndex;

- (IBAction)updateSelectedVariable:(NSPopUpButton *)sender;

@end

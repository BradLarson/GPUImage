#import "SLSFilterShowcaseWindowController.h"

@interface SLSFilterShowcaseWindowController ()

@end

@implementation SLSFilterShowcaseWindowController

@synthesize glView = _glView;
@synthesize enableSlider = _enableSlider;
@synthesize minimumSliderValue = _minimumSliderValue, maximumSliderValue = _maximumSliderValue, currentSliderValue = _currentSliderValue;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    inputCamera = [[GPUImageAVCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionUnspecified];
    
    currentlySelectedRow = 1;
    [self changeSelectedRow:0];
    
    [inputCamera startCameraCapture];
}

#pragma mark -
#pragma mark Filter switching

- (void)changeSelectedRow:(NSUInteger)newRowIndex;
{
    if (newRowIndex == currentlySelectedRow)
    {
        return;
    }
    
    currentlySelectedRow = newRowIndex;
    
    if (currentlySelectedFilter != nil)
    {
        [inputCamera removeAllTargets];
        // Disconnect older filter before replacing with new one
        [currentlySelectedFilter removeAllTargets];
        currentlySelectedFilter = nil;
    }
    
    switch(currentlySelectedRow)
    {
        case GPUIMAGE_BRIGHTNESS:
        {
            currentlySelectedFilter = [[GPUImageBrightnessFilter alloc] init];

            self.minimumSliderValue = -1.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.0;
            self.enableSlider = YES;
        }; break;
    }

    [inputCamera addTarget:currentlySelectedFilter];
    [currentlySelectedFilter addTarget:self.glView];
}

#pragma mark -
#pragma mark Filter settings

- (void)setCurrentSliderValue:(CGFloat)newValue;
{
    _currentSliderValue = newValue;
    switch(currentlySelectedRow)
    {
        case GPUIMAGE_BRIGHTNESS: [(GPUImageBrightnessFilter *)currentlySelectedFilter setBrightness:_currentSliderValue]; break;
    }
}

#pragma mark -
#pragma mark NSTableView delegate methods

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return GPUIMAGE_NUMFILTERS;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSString *tableRowTitle = nil;
    
    switch(rowIndex)
    {
        case GPUIMAGE_BRIGHTNESS: tableRowTitle = @"Brightness"; break;
    }
	
	return tableRowTitle;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
{
	NSInteger rowIndex = [[aNotification object] selectedRow];
    
    [self changeSelectedRow:rowIndex];
}

@end

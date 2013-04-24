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
        case GPUIMAGE_SATURATION:
        {
            currentlySelectedFilter = [[GPUImageSaturationFilter alloc] init];

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 2.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_CONTRAST:
        {
            currentlySelectedFilter = [[GPUImageContrastFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 4.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_BRIGHTNESS:
        {
            currentlySelectedFilter = [[GPUImageBrightnessFilter alloc] init];

            self.minimumSliderValue = -1.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_LEVELS:
        {
            currentlySelectedFilter = [[GPUImageLevelsFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_EXPOSURE:
        {
            currentlySelectedFilter = [[GPUImageExposureFilter alloc] init];
            
            self.minimumSliderValue = -4.0;
            self.maximumSliderValue = 4.0;
            self.currentSliderValue = 0.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_RGB:
        {
            currentlySelectedFilter = [[GPUImageRGBFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 2.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_HUE:
        {
            currentlySelectedFilter = [[GPUImageHueFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 360.0;
            self.currentSliderValue = 90.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_WHITEBALANCE:
        {
            currentlySelectedFilter = [[GPUImageWhiteBalanceFilter alloc] init];
            
            self.minimumSliderValue = 2500.0;
            self.maximumSliderValue = 7500.0;
            self.currentSliderValue = 5000.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_MONOCHROME:
        {
            currentlySelectedFilter = [[GPUImageMonochromeFilter alloc] init];
            [(GPUImageMonochromeFilter *)currentlySelectedFilter setColor:(GPUVector4){0.0f, 0.0f, 1.0f, 1.f}];

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_GRAYSCALE:
        {
            currentlySelectedFilter = [[GPUImageGrayscaleFilter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_PIXELLATE:
        {
            currentlySelectedFilter = [[GPUImagePixellateFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 0.3;
            self.currentSliderValue = 0.05;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_SOBELEDGEDETECTION:
        {
            currentlySelectedFilter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_SKETCH:
        {
            currentlySelectedFilter = [[GPUImageSketchFilter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_TOON:
        {
            currentlySelectedFilter = [[GPUImageToonFilter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_KUWAHARA:
        {
            currentlySelectedFilter = [[GPUImageKuwaharaFilter alloc] init];
            
            self.minimumSliderValue = 3.0;
            self.maximumSliderValue = 8.0;
            self.currentSliderValue = 3.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_GAUSSIANBLUR:
        {
            currentlySelectedFilter = [[GPUImageGaussianBlurFilter alloc] init];

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_BILATERAL:
        {
            currentlySelectedFilter = [[GPUImageBilateralFilter alloc] init];

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 5.0;
            self.currentSliderValue = 1.0;
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
        case GPUIMAGE_SATURATION: [(GPUImageSaturationFilter *)currentlySelectedFilter setSaturation:_currentSliderValue]; break;
        case GPUIMAGE_CONTRAST: [(GPUImageContrastFilter *)currentlySelectedFilter setContrast:_currentSliderValue]; break;
        case GPUIMAGE_BRIGHTNESS: [(GPUImageBrightnessFilter *)currentlySelectedFilter setBrightness:_currentSliderValue]; break;
        case GPUIMAGE_LEVELS: {
            [(GPUImageLevelsFilter *)currentlySelectedFilter setRedMin:_currentSliderValue gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            [(GPUImageLevelsFilter *)currentlySelectedFilter setGreenMin:_currentSliderValue gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            [(GPUImageLevelsFilter *)currentlySelectedFilter setBlueMin:_currentSliderValue gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
        }; break;
        case GPUIMAGE_EXPOSURE: [(GPUImageExposureFilter *)currentlySelectedFilter setExposure:_currentSliderValue]; break;
        case GPUIMAGE_RGB: [(GPUImageRGBFilter *)currentlySelectedFilter setGreen:_currentSliderValue]; break;
        case GPUIMAGE_HUE: [(GPUImageHueFilter *)currentlySelectedFilter setHue:_currentSliderValue]; break;
        case GPUIMAGE_WHITEBALANCE: [(GPUImageWhiteBalanceFilter *)currentlySelectedFilter setTemperature:_currentSliderValue]; break;
        case GPUIMAGE_MONOCHROME: [(GPUImageMonochromeFilter *)currentlySelectedFilter setIntensity:_currentSliderValue]; break;
        case GPUIMAGE_PIXELLATE: [(GPUImagePixellateFilter *)currentlySelectedFilter setFractionalWidthOfAPixel:_currentSliderValue]; break;
        case GPUIMAGE_KUWAHARA: [(GPUImageKuwaharaFilter *)currentlySelectedFilter setRadius:round(_currentSliderValue)]; break;
        case GPUIMAGE_GAUSSIANBLUR: [(GPUImageGaussianBlurFilter *)currentlySelectedFilter setBlurSize:_currentSliderValue]; break;
        case GPUIMAGE_BILATERAL: [(GPUImageBilateralFilter *)currentlySelectedFilter setDistanceNormalizationFactor:_currentSliderValue]; break;
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
        case GPUIMAGE_SATURATION: tableRowTitle = @"Saturation"; break;
        case GPUIMAGE_CONTRAST: tableRowTitle = @"Contrast"; break;
        case GPUIMAGE_BRIGHTNESS: tableRowTitle = @"Brightness"; break;
        case GPUIMAGE_LEVELS: tableRowTitle = @"Levels"; break;
        case GPUIMAGE_EXPOSURE: tableRowTitle = @"Exposure"; break;
        case GPUIMAGE_RGB: tableRowTitle = @"RGB"; break;
        case GPUIMAGE_HUE: tableRowTitle = @"Hue"; break;
        case GPUIMAGE_WHITEBALANCE: tableRowTitle = @"White balance"; break;
        case GPUIMAGE_MONOCHROME: tableRowTitle = @"Monochrome"; break;
        case GPUIMAGE_PIXELLATE: tableRowTitle = @"Pixellate"; break;
        case GPUIMAGE_GRAYSCALE: tableRowTitle = @"Grayscale"; break;
        case GPUIMAGE_SOBELEDGEDETECTION: tableRowTitle = @"Sobel edge detection"; break;
        case GPUIMAGE_SKETCH: tableRowTitle = @"Sketch"; break;
        case GPUIMAGE_TOON: tableRowTitle = @"Toon"; break;
        case GPUIMAGE_KUWAHARA: tableRowTitle = @"Kuwahara"; break;
        case GPUIMAGE_GAUSSIANBLUR: tableRowTitle = @"Gaussian Blur"; break;
        case GPUIMAGE_BILATERAL: tableRowTitle = @"Bilateral"; break;
    }
	
	return tableRowTitle;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
{
	NSInteger rowIndex = [[aNotification object] selectedRow];
    
    [self changeSelectedRow:rowIndex];
}

@end

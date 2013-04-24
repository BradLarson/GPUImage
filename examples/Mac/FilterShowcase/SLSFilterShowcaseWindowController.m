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
    inputCamera.runBenchmark = YES;
    
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
        case GPUIMAGE_FALSECOLOR:
        {
            currentlySelectedFilter = [[GPUImageFalseColorFilter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_SHARPEN:
        {
            currentlySelectedFilter = [[GPUImageSharpenFilter alloc] init];
            
            self.minimumSliderValue = -1.0;
            self.maximumSliderValue = 4.0;
            self.currentSliderValue = 0.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_UNSHARPMASK:
        {
            currentlySelectedFilter = [[GPUImageUnsharpMaskFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 5.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_TRANSFORM:
        {
            currentlySelectedFilter = [[GPUImageTransformFilter alloc] init];
            [(GPUImageTransformFilter *)currentlySelectedFilter setAffineTransform:CGAffineTransformMakeRotation(2.0)];

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 6.28;
            self.currentSliderValue = 2.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_TRANSFORM3D:
        {
            currentlySelectedFilter = [[GPUImageTransformFilter alloc] init];
            CATransform3D perspectiveTransform = CATransform3DIdentity;
            perspectiveTransform.m34 = 0.4;
            perspectiveTransform.m33 = 0.4;
            perspectiveTransform = CATransform3DScale(perspectiveTransform, 0.75, 0.75, 0.75);
            perspectiveTransform = CATransform3DRotate(perspectiveTransform, 0.75, 0.0, 1.0, 0.0);
            
            [(GPUImageTransformFilter *)currentlySelectedFilter setTransform3D:perspectiveTransform];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 6.28;
            self.currentSliderValue = 0.75;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_CROP:
        {
            currentlySelectedFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0, 0.0, 1.0, 0.25)];
            
            self.minimumSliderValue = 0.2;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.5;
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
        case GPUIMAGE_GAUSSIAN:
        {
            currentlySelectedFilter = [[GPUImageGaussianBlurFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 10.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE:
        {
            currentlySelectedFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            [(GPUImageGaussianSelectiveBlurFilter*)currentlySelectedFilter setExcludeCircleRadius:40.0/320.0];

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 0.75;
            self.currentSliderValue = 40.0/320.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_GAUSSIAN_POSITION:
        {
            currentlySelectedFilter = [[GPUImageGaussianBlurPositionFilter alloc] init];
            [(GPUImageGaussianBlurPositionFilter*)currentlySelectedFilter setBlurRadius:40.0/320.0];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 0.75;
            self.currentSliderValue = 40.0/320.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_FASTBLUR:
        {
            currentlySelectedFilter = [[GPUImageFastBlurFilter alloc] init];
            
            self.minimumSliderValue = 1.0;
            self.maximumSliderValue = 10.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_BOXBLUR:
        {
            currentlySelectedFilter = [[GPUImageBoxBlurFilter alloc] init];
            
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_MEDIAN:
        {
            currentlySelectedFilter = [[GPUImageMedianFilter alloc] init];
            
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_BILATERAL:
        {
            currentlySelectedFilter = [[GPUImageBilateralFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 10.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_MOTIONBLUR:
        {
            currentlySelectedFilter = [[GPUImageMotionBlurFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 180.0;
            self.currentSliderValue = 0.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_ZOOMBLUR:
        {
            currentlySelectedFilter = [[GPUImageZoomBlurFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 2.5;
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
        case GPUIMAGE_SHARPEN: [(GPUImageSharpenFilter *)currentlySelectedFilter setSharpness:_currentSliderValue]; break;
        case GPUIMAGE_UNSHARPMASK: [(GPUImageUnsharpMaskFilter *)currentlySelectedFilter setIntensity:_currentSliderValue]; break;
        case GPUIMAGE_TRANSFORM: [(GPUImageTransformFilter *)currentlySelectedFilter setAffineTransform:CGAffineTransformMakeRotation(_currentSliderValue)]; break;
        case GPUIMAGE_TRANSFORM3D:
        {
            CATransform3D perspectiveTransform = CATransform3DIdentity;
            perspectiveTransform.m34 = 0.4;
            perspectiveTransform.m33 = 0.4;
            perspectiveTransform = CATransform3DScale(perspectiveTransform, 0.75, 0.75, 0.75);
            perspectiveTransform = CATransform3DRotate(perspectiveTransform, _currentSliderValue, 0.0, 1.0, 0.0);
            
            [(GPUImageTransformFilter *)currentlySelectedFilter setTransform3D:perspectiveTransform];
        }; break;
        case GPUIMAGE_CROP: [(GPUImageCropFilter *)currentlySelectedFilter setCropRegion:CGRectMake(0.0, 0.0, 1.0, _currentSliderValue)]; break;
        case GPUIMAGE_GAUSSIAN: [(GPUImageGaussianBlurFilter *)currentlySelectedFilter setBlurSize:_currentSliderValue]; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE: [(GPUImageGaussianSelectiveBlurFilter *)currentlySelectedFilter setExcludeCircleRadius:_currentSliderValue]; break;
        case GPUIMAGE_GAUSSIAN_POSITION: [(GPUImageGaussianBlurPositionFilter *)currentlySelectedFilter setBlurRadius:_currentSliderValue]; break;
        case GPUIMAGE_FASTBLUR: [(GPUImageFastBlurFilter *)currentlySelectedFilter setBlurPasses:round(_currentSliderValue)]; break;
        case GPUIMAGE_BILATERAL: [(GPUImageBilateralFilter *)currentlySelectedFilter setDistanceNormalizationFactor:_currentSliderValue]; break;
        case GPUIMAGE_MOTIONBLUR: [(GPUImageMotionBlurFilter *)currentlySelectedFilter setBlurAngle:_currentSliderValue]; break;
        case GPUIMAGE_ZOOMBLUR: [(GPUImageZoomBlurFilter *)currentlySelectedFilter setBlurSize:_currentSliderValue]; break;
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
        case GPUIMAGE_FALSECOLOR: tableRowTitle = @"False color"; break;
        case GPUIMAGE_SHARPEN: tableRowTitle = @"Sharpen"; break;
        case GPUIMAGE_UNSHARPMASK: tableRowTitle = @"Unsharp mask"; break;
        case GPUIMAGE_TRANSFORM: tableRowTitle = @"Transform (2-D)"; break;
        case GPUIMAGE_TRANSFORM3D: tableRowTitle = @"Transform (3-D)"; break;
        case GPUIMAGE_CROP: tableRowTitle = @"Crop"; break;
        case GPUIMAGE_GAUSSIAN: tableRowTitle = @"Gaussian blur"; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE: tableRowTitle = @"Gaussian selective blur"; break;
        case GPUIMAGE_GAUSSIAN_POSITION: tableRowTitle = @"Gaussian (centered)"; break;
        case GPUIMAGE_FASTBLUR: tableRowTitle = @"Gaussian blur (optimized)"; break;
        case GPUIMAGE_BOXBLUR: tableRowTitle = @"Box blur"; break;
        case GPUIMAGE_MEDIAN: tableRowTitle = @"Median (3x3)"; break;
        case GPUIMAGE_BILATERAL: tableRowTitle = @"Bilateral blur"; break;
        case GPUIMAGE_MOTIONBLUR: tableRowTitle = @"Motion blur"; break;
        case GPUIMAGE_ZOOMBLUR: tableRowTitle = @"Zoom blur"; break;
    }
	
	return tableRowTitle;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
{
	NSInteger rowIndex = [[aNotification object] selectedRow];
    
    [self changeSelectedRow:rowIndex];
}

@end

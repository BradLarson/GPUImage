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
    BOOL needsSecondImage = NO;

    if (currentlySelectedFilter != nil)
    {
        [inputCamera removeAllTargets];
        [imageForBlending removeAllTargets];
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
        case GPUIMAGE_MASK:
        {
            currentlySelectedFilter = [[GPUImageMaskFilter alloc] init];
            [(GPUImageFilter*)currentlySelectedFilter setBackgroundColorRed:0.0 green:1.0 blue:0.0 alpha:1.0];
            self.enableSlider = NO;
            needsSecondImage = YES;
        }; break;
        case GPUIMAGE_GAMMA:
        {
            currentlySelectedFilter = [[GPUImageGammaFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 3.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_TONECURVE:
        {
            currentlySelectedFilter = [[GPUImageToneCurveFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.5;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_HIGHLIGHTSHADOW:
        {
            currentlySelectedFilter = [[GPUImageHighlightShadowFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_HAZE:
        {
            currentlySelectedFilter = [[GPUImageHazeFilter alloc] init];
            
            self.minimumSliderValue = -0.2;
            self.maximumSliderValue = 0.2;
            self.currentSliderValue = 0.2;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_SEPIA:
        {
            currentlySelectedFilter = [[GPUImageSepiaFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_AMATORKA:
        {
            currentlySelectedFilter = [[GPUImageAmatorkaFilter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_MISSETIKATE:
        {
            currentlySelectedFilter = [[GPUImageMissEtikateFilter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_SOFTELEGANCE:
        {
            currentlySelectedFilter = [[GPUImageSoftEleganceFilter alloc] init];
            self.enableSlider = NO;
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
        case GPUIMAGE_DISSOLVE:
        {
            currentlySelectedFilter = [[GPUImageDissolveBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.5;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_CHROMAKEY:
        {
            currentlySelectedFilter = [[GPUImageChromaKeyBlendFilter alloc] init];
            [(GPUImageChromaKeyBlendFilter *)currentlySelectedFilter setColorToReplaceRed:0.0 green:1.0 blue:0.0];

            needsSecondImage = YES;
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.4;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_ADD:
        {
            currentlySelectedFilter = [[GPUImageAddBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_DIVIDE:
        {
            currentlySelectedFilter = [[GPUImageDivideBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_MULTIPLY:
        {
            currentlySelectedFilter = [[GPUImageMultiplyBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_OVERLAY:
        {
            currentlySelectedFilter = [[GPUImageOverlayBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_LIGHTEN:
        {
            currentlySelectedFilter = [[GPUImageLightenBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_DARKEN:
        {
            currentlySelectedFilter = [[GPUImageDarkenBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_COLORBURN:
        {
            currentlySelectedFilter = [[GPUImageColorBurnBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_COLORDODGE:
        {
            currentlySelectedFilter = [[GPUImageColorDodgeBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_LINEARBURN:
        {
            currentlySelectedFilter = [[GPUImageLinearBurnBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_SCREENBLEND:
        {
            currentlySelectedFilter = [[GPUImageScreenBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_DIFFERENCEBLEND:
        {
            currentlySelectedFilter = [[GPUImageDifferenceBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_SUBTRACTBLEND:
        {
            currentlySelectedFilter = [[GPUImageSubtractBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_EXCLUSIONBLEND:
        {
            currentlySelectedFilter = [[GPUImageExclusionBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_HARDLIGHTBLEND:
        {
            currentlySelectedFilter = [[GPUImageHardLightBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_SOFTLIGHTBLEND:
        {
            currentlySelectedFilter = [[GPUImageSoftLightBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_COLORBLEND:
        {
            currentlySelectedFilter = [[GPUImageColorBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_HUEBLEND:
        {
            currentlySelectedFilter = [[GPUImageHueBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_SATURATIONBLEND:
        {
            currentlySelectedFilter = [[GPUImageSaturationBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_LUMINOSITYBLEND:
        {
            currentlySelectedFilter = [[GPUImageLuminosityBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_NORMALBLEND:
        {
            currentlySelectedFilter = [[GPUImageNormalBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_POISSONBLEND:
        {
            currentlySelectedFilter = [[GPUImagePoissonBlendFilter alloc] init];
            
            needsSecondImage = YES;
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.5;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_OPACITY:
        {
            currentlySelectedFilter = [[GPUImageOpacityFilter alloc] init];
            
            needsSecondImage = YES;
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
    }

    [inputCamera addTarget:currentlySelectedFilter];
    [currentlySelectedFilter addTarget:self.glView];
    
    if (needsSecondImage)
    {
        if (imageForBlending == nil)
        {
            NSImage *inputImage;
            
            if (currentlySelectedRow == GPUIMAGE_MASK)
            {
                inputImage = [NSImage imageNamed:@"mask"];
            }
            /*
             else if (filterType == GPUIMAGE_VORONOI) {
             inputImage = [UIImage imageNamed:@"voroni_points.png"];
             }*/
            else {
                // The picture is only used for two-image blend filters
                inputImage = [NSImage imageNamed:@"Lambeau.jpg"];
            }
            
            imageForBlending = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
        }
        [imageForBlending processImage];
        [imageForBlending addTarget:currentlySelectedFilter];
    }

    //    if ( (filterType == GPUIMAGE_OPACITY) || (filterType == GPUIMAGE_CHROMAKEYNONBLEND) )
    if (currentlySelectedRow == GPUIMAGE_OPACITY)
    {
        [currentlySelectedFilter removeTarget:self.glView];

        [imageForBlending removeTarget:currentlySelectedFilter];
        [inputCamera removeTarget:currentlySelectedFilter];
        [inputCamera addTarget:currentlySelectedFilter];
        
        GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        blendFilter.mix = 1.0;
        [imageForBlending addTarget:blendFilter];
        [currentlySelectedFilter addTarget:blendFilter];
        
        [blendFilter addTarget:self.glView];
    }
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
        case GPUIMAGE_GAMMA: [(GPUImageGammaFilter *)currentlySelectedFilter setGamma:_currentSliderValue]; break;
        case GPUIMAGE_TONECURVE: [(GPUImageToneCurveFilter *)currentlySelectedFilter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithPoint:NSMakePoint(0.0, 0.0)], [NSValue valueWithPoint:NSMakePoint(0.5, _currentSliderValue)], [NSValue valueWithPoint:NSMakePoint(1.0, 0.75)], nil]]; break;
        case GPUIMAGE_HIGHLIGHTSHADOW: [(GPUImageHighlightShadowFilter *)currentlySelectedFilter setHighlights:_currentSliderValue]; break;
        case GPUIMAGE_HAZE: [(GPUImageHazeFilter *)currentlySelectedFilter setDistance:_currentSliderValue]; break;
        case GPUIMAGE_SEPIA: [(GPUImageSepiaFilter *)currentlySelectedFilter setIntensity:_currentSliderValue]; break;
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
        case GPUIMAGE_DISSOLVE: [(GPUImageDissolveBlendFilter *)currentlySelectedFilter setMix:_currentSliderValue]; break;
        case GPUIMAGE_CHROMAKEY: [(GPUImageChromaKeyBlendFilter *)currentlySelectedFilter setThresholdSensitivity:_currentSliderValue]; break;
        case GPUIMAGE_POISSONBLEND: [(GPUImagePoissonBlendFilter *)currentlySelectedFilter setMix:_currentSliderValue]; break;
        case GPUIMAGE_OPACITY:  [(GPUImageOpacityFilter *)currentlySelectedFilter setOpacity:_currentSliderValue]; break;
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
        case GPUIMAGE_MASK: tableRowTitle = @"Mask"; break;
        case GPUIMAGE_GAMMA: tableRowTitle = @"Gamma"; break;
        case GPUIMAGE_TONECURVE: tableRowTitle = @"Tone curve"; break;
        case GPUIMAGE_HIGHLIGHTSHADOW: tableRowTitle = @"Highlights and shadows"; break;
        case GPUIMAGE_HAZE: tableRowTitle = @"Haze"; break;
        case GPUIMAGE_SEPIA: tableRowTitle = @"Sepia tone"; break;
        case GPUIMAGE_AMATORKA: tableRowTitle = @"Amatorka (Lookup)"; break;
        case GPUIMAGE_MISSETIKATE: tableRowTitle = @"Miss Etikate (Lookup)"; break;
        case GPUIMAGE_SOFTELEGANCE: tableRowTitle = @"Soft elegance (Lookup)"; break;
        case GPUIMAGE_GAUSSIAN: tableRowTitle = @"Gaussian blur"; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE: tableRowTitle = @"Gaussian selective blur"; break;
        case GPUIMAGE_GAUSSIAN_POSITION: tableRowTitle = @"Gaussian (centered)"; break;
        case GPUIMAGE_FASTBLUR: tableRowTitle = @"Gaussian blur (optimized)"; break;
        case GPUIMAGE_BOXBLUR: tableRowTitle = @"Box blur"; break;
        case GPUIMAGE_MEDIAN: tableRowTitle = @"Median (3x3)"; break;
        case GPUIMAGE_BILATERAL: tableRowTitle = @"Bilateral blur"; break;
        case GPUIMAGE_MOTIONBLUR: tableRowTitle = @"Motion blur"; break;
        case GPUIMAGE_ZOOMBLUR: tableRowTitle = @"Zoom blur"; break;
        case GPUIMAGE_DISSOLVE: tableRowTitle = @"Dissolve blend"; break;
        case GPUIMAGE_CHROMAKEY: tableRowTitle = @"Chroma key blend (green)"; break;
        case GPUIMAGE_ADD: tableRowTitle = @"Add blend"; break;
        case GPUIMAGE_DIVIDE: tableRowTitle = @"Divide blend"; break;
        case GPUIMAGE_MULTIPLY: tableRowTitle = @"Multiply blend"; break;
        case GPUIMAGE_OVERLAY: tableRowTitle = @"Overlay blend"; break;
        case GPUIMAGE_LIGHTEN: tableRowTitle = @"Lighten blend"; break;
        case GPUIMAGE_DARKEN: tableRowTitle = @"Darken blend"; break;
        case GPUIMAGE_COLORBURN: tableRowTitle = @"Color burn blend"; break;
        case GPUIMAGE_COLORDODGE: tableRowTitle = @"Color dodge blend"; break;
        case GPUIMAGE_LINEARBURN: tableRowTitle = @"Linear burn blend"; break;
        case GPUIMAGE_SCREENBLEND: tableRowTitle = @"Screen blend"; break;
        case GPUIMAGE_DIFFERENCEBLEND: tableRowTitle = @"Difference blend"; break;
        case GPUIMAGE_SUBTRACTBLEND: tableRowTitle = @"Subtract blend"; break;
        case GPUIMAGE_EXCLUSIONBLEND: tableRowTitle = @"Exclusion blend"; break;
        case GPUIMAGE_HARDLIGHTBLEND: tableRowTitle = @"Hard light blend"; break;
        case GPUIMAGE_SOFTLIGHTBLEND: tableRowTitle = @"Soft light blend"; break;
        case GPUIMAGE_COLORBLEND: tableRowTitle = @"Color blend"; break;
        case GPUIMAGE_HUEBLEND: tableRowTitle = @"Hue blend"; break;
        case GPUIMAGE_SATURATIONBLEND: tableRowTitle = @"Saturation blend"; break;
        case GPUIMAGE_LUMINOSITYBLEND: tableRowTitle = @"Luminosity blend"; break;
        case GPUIMAGE_NORMALBLEND: tableRowTitle = @"Normal blend"; break;
        case GPUIMAGE_POISSONBLEND: tableRowTitle = @"Poisson blend"; break;
        case GPUIMAGE_OPACITY: tableRowTitle = @"Opacity adjustment"; break;
    }
	
	return tableRowTitle;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
{
	NSInteger rowIndex = [[aNotification object] selectedRow];
    
    [self changeSelectedRow:rowIndex];
}

@end

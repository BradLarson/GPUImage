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

    inputCamera = [[GPUImageAVCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraDevice:nil];
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
        case GPUIMAGE_COLORINVERT:
        {
            currentlySelectedFilter = [[GPUImageColorInvertFilter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_HISTOGRAM:
        {
            currentlySelectedFilter = [[GPUImageHistogramFilter alloc] init];
            
            self.minimumSliderValue = 4.0;
            self.maximumSliderValue = 32.0;
            self.currentSliderValue = 16.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_AVERAGECOLOR:
        {
            currentlySelectedFilter = [[GPUImageAverageColor alloc] init];
            self.enableSlider = NO;
        }; break;
		case GPUIMAGE_LUMINOSITY:
        {
            currentlySelectedFilter = [[GPUImageLuminosity alloc] init];
            self.enableSlider = NO;
        }; break;
		case GPUIMAGE_THRESHOLD:
        {
            currentlySelectedFilter = [[GPUImageLuminanceThresholdFilter alloc] init];

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.5;
            self.enableSlider = YES;
        }; break;
		case GPUIMAGE_ADAPTIVETHRESHOLD:
        {
            currentlySelectedFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
            
            self.minimumSliderValue = 1.0;
            self.maximumSliderValue = 20.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
		case GPUIMAGE_AVERAGELUMINANCETHRESHOLD:
        {
            currentlySelectedFilter = [[GPUImageAverageLuminanceThresholdFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 2.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;

        case GPUIMAGE_HARRISCORNERDETECTION:
        {
            currentlySelectedFilter = [[GPUImageHarrisCornerDetectionFilter alloc] init];
            [(GPUImageHarrisCornerDetectionFilter *)currentlySelectedFilter setThreshold:0.20];

            self.minimumSliderValue = 0.01;
            self.maximumSliderValue = 0.70;
            self.currentSliderValue = 0.20;
            self.enableSlider = YES;
        }; break;
		case GPUIMAGE_NOBLECORNERDETECTION:
        {
            currentlySelectedFilter = [[GPUImageNobleCornerDetectionFilter alloc] init];
            [(GPUImageNobleCornerDetectionFilter *)currentlySelectedFilter setThreshold:0.20];

            self.minimumSliderValue = 0.01;
            self.maximumSliderValue = 0.70;
            self.currentSliderValue = 0.20;
            self.enableSlider = YES;
        }; break;
		case GPUIMAGE_SHITOMASIFEATUREDETECTION:
        {
            currentlySelectedFilter = [[GPUImageShiTomasiFeatureDetectionFilter alloc] init];
            [(GPUImageShiTomasiFeatureDetectionFilter *)currentlySelectedFilter setThreshold:0.20];

            self.minimumSliderValue = 0.01;
            self.maximumSliderValue = 0.70;
            self.currentSliderValue = 0.20;
            self.enableSlider = YES;
        }; break;
		case GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR:
        {
            currentlySelectedFilter = [[GPUImageHoughTransformLineDetector alloc] init];
            [(GPUImageHoughTransformLineDetector *)currentlySelectedFilter setLineDetectionThreshold:0.60];

            self.minimumSliderValue = 0.2;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.6;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_BUFFER:
        {
            currentlySelectedFilter = [[GPUImageBuffer alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_LOWPASS:
        {
            currentlySelectedFilter = [[GPUImageLowPassFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.5;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_HIGHPASS:
        {
            currentlySelectedFilter = [[GPUImageHighPassFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.5;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_MOTIONDETECTOR:
        {
            currentlySelectedFilter = [[GPUImageMotionDetector alloc] init];
            
            self.minimumSliderValue = 0.0;
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
        case GPUIMAGE_POLARPIXELLATE:
        {
            currentlySelectedFilter = [[GPUImagePolarPixellateFilter alloc] init];
            
            self.minimumSliderValue = -0.1;
            self.maximumSliderValue = 0.1;
            self.currentSliderValue = 0.05;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_PIXELLATE_POSITION:
        {
            currentlySelectedFilter = [[GPUImagePixellatePositionFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 0.5;
            self.currentSliderValue = 0.25;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_POLKADOT:
        {
            currentlySelectedFilter = [[GPUImagePolkaDotFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 0.3;
            self.currentSliderValue = 0.05;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_HALFTONE:
        {
            currentlySelectedFilter = [[GPUImageHalftoneFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 0.05;
            self.currentSliderValue = 0.01;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_CROSSHATCH:
        {
            currentlySelectedFilter = [[GPUImageCrosshatchFilter alloc] init];
            
            self.minimumSliderValue = 0.01;
            self.maximumSliderValue = 0.06;
            self.currentSliderValue = 0.03;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_SOBELEDGEDETECTION:
        {
            currentlySelectedFilter = [[GPUImageSobelEdgeDetectionFilter alloc] init];

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 2.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_PREWITTEDGEDETECTION:
        {
            currentlySelectedFilter = [[GPUImagePrewittEdgeDetectionFilter alloc] init];

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 2.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_CANNYEDGEDETECTION:
        {
            currentlySelectedFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION:
        {
            currentlySelectedFilter = [[GPUImageThresholdEdgeDetectionFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.5;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_XYGRADIENT:
        {
            currentlySelectedFilter = [[GPUImageXYDerivativeFilter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_SKETCH:
        {
            currentlySelectedFilter = [[GPUImageSketchFilter alloc] init];

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 2.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_THRESHOLDSKETCH:
        {
            currentlySelectedFilter = [[GPUImageThresholdSketchFilter alloc] init];
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.25;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_TOON:
        {
            currentlySelectedFilter = [[GPUImageToonFilter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_CONVOLUTION:
        {
            currentlySelectedFilter = [[GPUImage3x3ConvolutionFilter alloc] init];
            
            [(GPUImage3x3ConvolutionFilter *)currentlySelectedFilter setConvolutionKernel:(GPUMatrix3x3){
                {-1.0f,  0.0f, 1.0f},
                {-2.0f, 0.0f, 2.0f},
                {-1.0f,  0.0f, 1.0f}
            }];

            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_SMOOTHTOON:
        {
            currentlySelectedFilter = [[GPUImageSmoothToonFilter alloc] init];
            self.minimumSliderValue = 1.0;
            self.maximumSliderValue = 6.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_TILTSHIFT:
        {
            currentlySelectedFilter = [[GPUImageTiltShiftFilter alloc] init];
            [(GPUImageTiltShiftFilter *)currentlySelectedFilter setTopFocusLevel:0.4];
            [(GPUImageTiltShiftFilter *)currentlySelectedFilter setBottomFocusLevel:0.6];
            [(GPUImageTiltShiftFilter *)currentlySelectedFilter setFocusFallOffRate:0.2];

            self.minimumSliderValue = 0.2;
            self.maximumSliderValue = 0.8;
            self.currentSliderValue = 0.5;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_CGA:
        {
            currentlySelectedFilter = [[GPUImageCGAColorspaceFilter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_POSTERIZE:
        {
            currentlySelectedFilter = [[GPUImagePosterizeFilter alloc] init];
            self.minimumSliderValue = 1.0;
            self.maximumSliderValue = 20.0;
            self.currentSliderValue = 10.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_EMBOSS:
        {
            currentlySelectedFilter = [[GPUImageEmbossFilter alloc] init];
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 5.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_LAPLACIAN:
        {
            currentlySelectedFilter = [[GPUImageLaplacianFilter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_CHROMAKEYNONBLEND:
        {
            currentlySelectedFilter = [[GPUImageChromaKeyFilter alloc] init];
            [(GPUImageChromaKeyFilter *)currentlySelectedFilter setColorToReplaceRed:0.0 green:1.0 blue:0.0];

            needsSecondImage = YES;

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.4;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_KUWAHARA:
        {
            currentlySelectedFilter = [[GPUImageKuwaharaFilter alloc] init];
            
            self.minimumSliderValue = 3.0;
            self.maximumSliderValue = 8.0;
            self.currentSliderValue = 3.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_KUWAHARARADIUS3:
        {
            currentlySelectedFilter = [[GPUImageKuwaharaRadius3Filter alloc] init];
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_VIGNETTE:
        {
            currentlySelectedFilter = [[GPUImageVignetteFilter alloc] init];
            self.minimumSliderValue = 0.5;
            self.maximumSliderValue = 0.9;
            self.currentSliderValue = 0.75;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_GAUSSIAN:
        {
            currentlySelectedFilter = [[GPUImageGaussianBlurFilter alloc] init];
            
            self.minimumSliderValue = 1.0;
            self.maximumSliderValue = 24.0;
            self.currentSliderValue = 2.0;
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
        case GPUIMAGE_BOXBLUR:
        {
            currentlySelectedFilter = [[GPUImageBoxBlurFilter alloc] init];
            
            self.minimumSliderValue = 1.0;
            self.maximumSliderValue = 24.0;
            self.currentSliderValue = 2.0;
            self.enableSlider = YES;
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
        case GPUIMAGE_SWIRL:
        {
            currentlySelectedFilter = [[GPUImageSwirlFilter alloc] init];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 2.0;
            self.currentSliderValue = 1.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_BULGE:
        {
            currentlySelectedFilter = [[GPUImageBulgeDistortionFilter alloc] init];
            
            self.minimumSliderValue = -1.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.5;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_PINCH:
        {
            currentlySelectedFilter = [[GPUImagePinchDistortionFilter alloc] init];
            
            self.minimumSliderValue = -2.0;
            self.maximumSliderValue = 2.0;
            self.currentSliderValue = 0.5;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_SPHEREREFRACTION:
        {
            currentlySelectedFilter = [[GPUImageSphereRefractionFilter alloc] init];
            [(GPUImageSphereRefractionFilter *)currentlySelectedFilter setRadius:0.15];

            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.15;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_GLASSSPHERE:
        {
            currentlySelectedFilter = [[GPUImageGlassSphereFilter alloc] init];
            [(GPUImageGlassSphereFilter *)currentlySelectedFilter setRadius:0.15];
            
            self.minimumSliderValue = 0.0;
            self.maximumSliderValue = 1.0;
            self.currentSliderValue = 0.15;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_STRETCH:
        {
            currentlySelectedFilter = [[GPUImageStretchDistortionFilter alloc] init];
            
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_DILATION:
        {
            currentlySelectedFilter = [[GPUImageRGBDilationFilter alloc] init];
            
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_EROSION:
        {
            currentlySelectedFilter = [[GPUImageRGBErosionFilter alloc] init];
            
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_OPENING:
        {
            currentlySelectedFilter = [[GPUImageRGBOpeningFilter alloc] init];
            
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_CLOSING:
        {
            currentlySelectedFilter = [[GPUImageRGBClosingFilter alloc] init];
            
            self.enableSlider = NO;
        }; break;
        case GPUIMAGE_PERLINNOISE:
        {
            currentlySelectedFilter = [[GPUImagePerlinNoiseFilter alloc] init];
            
            self.minimumSliderValue = 1.0;
            self.maximumSliderValue = 30.0;
            self.currentSliderValue = 8.0;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_VORONOI:
        {
            self.enableSlider = NO;
            
            GPUImageJFAVoronoiFilter *jfa = [[GPUImageJFAVoronoiFilter alloc] init];
            [jfa setSizeInPixels:CGSizeMake(1024.0, 1024.0)];
            
            NSImage *voronoiPoints = [NSImage imageNamed:@"voroni_points2.png"];

            imageForBlending = [[GPUImagePicture alloc] initWithImage:voronoiPoints];
            
            [imageForBlending addTarget:jfa];
            
            currentlySelectedFilter = [[GPUImageVoronoiConsumerFilter alloc] init];
            
            [jfa setSizeInPixels:CGSizeMake(1024.0, 1024.0)];
            [(GPUImageVoronoiConsumerFilter *)currentlySelectedFilter setSizeInPixels:CGSizeMake(1024.0, 1024.0)];
            
            [inputCamera addTarget:currentlySelectedFilter];
            [jfa addTarget:currentlySelectedFilter];
            [imageForBlending processImage];
        }; break;
        case GPUIMAGE_MOSAIC:
        {
            currentlySelectedFilter = [[GPUImageMosaicFilter alloc] init];
            [(GPUImageMosaicFilter *)currentlySelectedFilter setTileSet:@"squares.png"];
            [(GPUImageMosaicFilter *)currentlySelectedFilter setColorOn:NO];
//            [currentlySelectedFilter setInputRotation:kGPUImageRotateRight atIndex:0];

            self.minimumSliderValue = 0.002;
            self.maximumSliderValue = 0.05;
            self.currentSliderValue = 0.025;
            self.enableSlider = YES;
        }; break;
        case GPUIMAGE_LOCALBINARYPATTERN:
        {
            currentlySelectedFilter = [[GPUImageLocalBinaryPatternFilter alloc] init];
            
            self.minimumSliderValue = 1.0;
            self.maximumSliderValue = 5.0;
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

    if (currentlySelectedRow != GPUIMAGE_VORONOI)
    {
        [inputCamera addTarget:currentlySelectedFilter];
    }

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

    if ( (currentlySelectedRow == GPUIMAGE_OPACITY) || (currentlySelectedRow == GPUIMAGE_CHROMAKEYNONBLEND) )
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
    else if (currentlySelectedRow == GPUIMAGE_BUFFER)
    {
        [currentlySelectedFilter removeTarget:self.glView];
        
        GPUImageDifferenceBlendFilter *blendFilter = [[GPUImageDifferenceBlendFilter alloc] init];
        
        [inputCamera removeTarget:currentlySelectedFilter];
        
        GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
        [inputCamera addTarget:gammaFilter];
        [gammaFilter addTarget:blendFilter];
        [inputCamera addTarget:currentlySelectedFilter];
        
        [currentlySelectedFilter addTarget:blendFilter];
        
        [blendFilter addTarget:self.glView];
    }
    else if (currentlySelectedRow == GPUIMAGE_HISTOGRAM)
    {
        [currentlySelectedFilter removeTarget:self.glView];

        // I'm adding an intermediary filter because glReadPixels() requires something to be rendered for its glReadPixels() operation to work
        [inputCamera removeTarget:currentlySelectedFilter];
        GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
        [inputCamera addTarget:gammaFilter];
        [gammaFilter addTarget:currentlySelectedFilter];
        
        GPUImageHistogramGenerator *histogramGraph = [[GPUImageHistogramGenerator alloc] init];
        
        [histogramGraph forceProcessingAtSize:CGSizeMake(256.0, 144.0)];
        [currentlySelectedFilter addTarget:histogramGraph];
        
        GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        blendFilter.mix = 0.75;
        [blendFilter forceProcessingAtSize:CGSizeMake(256.0, 144.0)];
        
        [inputCamera addTarget:blendFilter];
        [histogramGraph addTarget:blendFilter];
        
        [blendFilter addTarget:self.glView];
    }
    else if ( (currentlySelectedRow == GPUIMAGE_SPHEREREFRACTION) || (currentlySelectedRow == GPUIMAGE_GLASSSPHERE) )
    {
        [currentlySelectedFilter removeTarget:self.glView];

        // Provide a blurred image for a cool-looking background
        GPUImageGaussianBlurFilter *gaussianBlur = [[GPUImageGaussianBlurFilter alloc] init];
        [inputCamera addTarget:gaussianBlur];
        gaussianBlur.blurRadiusInPixels = 10.0;
        
        GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        blendFilter.mix = 1.0;
        [gaussianBlur addTarget:blendFilter];
        [currentlySelectedFilter addTarget:blendFilter];
        
        [blendFilter addTarget:self.glView];
    }
    else if (currentlySelectedRow == GPUIMAGE_AVERAGECOLOR)
    {
        [currentlySelectedFilter removeTarget:self.glView];

        GPUImageSolidColorGenerator *colorGenerator = [[GPUImageSolidColorGenerator alloc] init];
        [colorGenerator forceProcessingAtSize:[self.glView sizeInPixels]];
        
        [(GPUImageAverageColor *)currentlySelectedFilter setColorAverageProcessingFinishedBlock:^(CGFloat redComponent, CGFloat greenComponent, CGFloat blueComponent, CGFloat alphaComponent, CMTime frameTime) {
            [colorGenerator setColorRed:redComponent green:greenComponent blue:blueComponent alpha:alphaComponent];
            //                NSLog(@"Average color: %f, %f, %f, %f", redComponent, greenComponent, blueComponent, alphaComponent);
        }];
        
        [colorGenerator addTarget:self.glView];
    }
    else if (currentlySelectedRow == GPUIMAGE_LUMINOSITY)
    {
        [currentlySelectedFilter removeTarget:self.glView];

        GPUImageSolidColorGenerator *colorGenerator = [[GPUImageSolidColorGenerator alloc] init];
        [colorGenerator forceProcessingAtSize:[self.glView sizeInPixels]];
        
        [(GPUImageLuminosity *)currentlySelectedFilter setLuminosityProcessingFinishedBlock:^(CGFloat luminosity, CMTime frameTime) {
            [colorGenerator setColorRed:luminosity green:luminosity blue:luminosity alpha:1.0];
        }];
        
        [colorGenerator addTarget:self.glView];
    }
    else if ( (currentlySelectedRow == GPUIMAGE_HARRISCORNERDETECTION) || (currentlySelectedRow == GPUIMAGE_NOBLECORNERDETECTION) || (currentlySelectedRow == GPUIMAGE_SHITOMASIFEATUREDETECTION) )
    {
        [currentlySelectedFilter removeTarget:self.glView];

        GPUImageCrosshairGenerator *crosshairGenerator = [[GPUImageCrosshairGenerator alloc] init];
        crosshairGenerator.crosshairWidth = 15.0;
        [crosshairGenerator forceProcessingAtSize:[self.glView sizeInPixels]];
        
        [(GPUImageHarrisCornerDetectionFilter *)currentlySelectedFilter setCornersDetectedBlock:^(GLfloat* cornerArray, NSUInteger cornersDetected, CMTime frameTime) {
            [crosshairGenerator renderCrosshairsFromArray:cornerArray count:cornersDetected frameTime:frameTime];
        }];
        
        GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        [blendFilter forceProcessingAtSize:[self.glView sizeInPixels]];
        GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
        [inputCamera addTarget:gammaFilter];
        [gammaFilter addTarget:blendFilter];
        
        [crosshairGenerator addTarget:blendFilter];
        
        [blendFilter addTarget:self.glView];
    }
    else if (currentlySelectedRow == GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR)
    {
        [currentlySelectedFilter removeTarget:self.glView];

        GPUImageLineGenerator *lineGenerator = [[GPUImageLineGenerator alloc] init];
        //            lineGenerator.crosshairWidth = 15.0;
        [lineGenerator forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
        [lineGenerator setLineColorRed:1.0 green:0.0 blue:0.0];
        [(GPUImageHoughTransformLineDetector *)currentlySelectedFilter setLinesDetectedBlock:^(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime){
            [lineGenerator renderLinesFromArray:lineArray count:linesDetected frameTime:frameTime];
        }];
        
        GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        [blendFilter forceProcessingAtSize:[self.glView sizeInPixels]];
        GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
        [inputCamera addTarget:gammaFilter];
        [gammaFilter addTarget:blendFilter];
        
        [lineGenerator addTarget:blendFilter];
        
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
        case GPUIMAGE_POLARPIXELLATE: [(GPUImagePolarPixellateFilter *)currentlySelectedFilter setPixelSize:CGSizeMake(_currentSliderValue, _currentSliderValue)]; break;
        case GPUIMAGE_PIXELLATE_POSITION: [(GPUImagePixellatePositionFilter *)currentlySelectedFilter setRadius:_currentSliderValue]; break;
        case GPUIMAGE_POLKADOT: [(GPUImagePolkaDotFilter *)currentlySelectedFilter setFractionalWidthOfAPixel:_currentSliderValue]; break;
        case GPUIMAGE_HALFTONE: [(GPUImageHalftoneFilter *)currentlySelectedFilter setFractionalWidthOfAPixel:_currentSliderValue]; break;
        case GPUIMAGE_CROSSHATCH: [(GPUImageCrosshatchFilter *)currentlySelectedFilter setCrossHatchSpacing:_currentSliderValue]; break;
        case GPUIMAGE_SOBELEDGEDETECTION: [(GPUImageSobelEdgeDetectionFilter *)currentlySelectedFilter setEdgeStrength:_currentSliderValue]; break;
        case GPUIMAGE_PREWITTEDGEDETECTION: [(GPUImagePrewittEdgeDetectionFilter *)currentlySelectedFilter setEdgeStrength:_currentSliderValue]; break;
        case GPUIMAGE_HISTOGRAM: [(GPUImageHistogramFilter *)currentlySelectedFilter setDownsamplingFactor:round(_currentSliderValue)]; break;
        case GPUIMAGE_THRESHOLD: [(GPUImageLuminanceThresholdFilter *)currentlySelectedFilter setThreshold:_currentSliderValue]; break;
        case GPUIMAGE_ADAPTIVETHRESHOLD: [(GPUImageAdaptiveThresholdFilter *)currentlySelectedFilter setBlurRadiusInPixels:_currentSliderValue]; break;
        case GPUIMAGE_AVERAGELUMINANCETHRESHOLD: [(GPUImageAverageLuminanceThresholdFilter *)currentlySelectedFilter setThresholdMultiplier:_currentSliderValue]; break;        
        case GPUIMAGE_CANNYEDGEDETECTION: [(GPUImageCannyEdgeDetectionFilter *)currentlySelectedFilter setBlurTexelSpacingMultiplier:_currentSliderValue]; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION: [(GPUImageThresholdEdgeDetectionFilter *)currentlySelectedFilter setThreshold:_currentSliderValue]; break;
        case GPUIMAGE_HARRISCORNERDETECTION: [(GPUImageHarrisCornerDetectionFilter *)currentlySelectedFilter setThreshold:_currentSliderValue]; break;
        case GPUIMAGE_NOBLECORNERDETECTION: [(GPUImageNobleCornerDetectionFilter *)currentlySelectedFilter setThreshold:_currentSliderValue]; break;
        case GPUIMAGE_SHITOMASIFEATUREDETECTION: [(GPUImageShiTomasiFeatureDetectionFilter *)currentlySelectedFilter setThreshold:_currentSliderValue]; break;
        case GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR: [(GPUImageHoughTransformLineDetector *)currentlySelectedFilter setLineDetectionThreshold:_currentSliderValue]; break;
        case GPUIMAGE_LOWPASS: [(GPUImageLowPassFilter *)currentlySelectedFilter setFilterStrength:_currentSliderValue]; break;
        case GPUIMAGE_HIGHPASS: [(GPUImageHighPassFilter *)currentlySelectedFilter setFilterStrength:_currentSliderValue]; break;
        case GPUIMAGE_MOTIONDETECTOR: [(GPUImageMotionDetector *)currentlySelectedFilter setLowPassFilterStrength:_currentSliderValue]; break;
        case GPUIMAGE_SKETCH: [(GPUImageSketchFilter *)currentlySelectedFilter setEdgeStrength:_currentSliderValue]; break;
        case GPUIMAGE_THRESHOLDSKETCH: [(GPUImageThresholdSketchFilter *)currentlySelectedFilter setThreshold:_currentSliderValue]; break;
        case GPUIMAGE_SMOOTHTOON: [(GPUImageSmoothToonFilter *)currentlySelectedFilter setBlurRadiusInPixels:_currentSliderValue]; break;
        case GPUIMAGE_POSTERIZE: [(GPUImagePosterizeFilter *)currentlySelectedFilter setColorLevels:round(_currentSliderValue)]; break;
        case GPUIMAGE_TILTSHIFT:
        {
            CGFloat midpoint = _currentSliderValue;
            [(GPUImageTiltShiftFilter *)currentlySelectedFilter setTopFocusLevel:midpoint - 0.1];
            [(GPUImageTiltShiftFilter *)currentlySelectedFilter setBottomFocusLevel:midpoint + 0.1];
        }; break;
        case GPUIMAGE_EMBOSS: [(GPUImageEmbossFilter *)currentlySelectedFilter setIntensity:_currentSliderValue]; break;
        case GPUIMAGE_CHROMAKEYNONBLEND: [(GPUImageChromaKeyFilter *)currentlySelectedFilter setThresholdSensitivity:_currentSliderValue]; break;
        case GPUIMAGE_KUWAHARA: [(GPUImageKuwaharaFilter *)currentlySelectedFilter setRadius:round(_currentSliderValue)]; break;
        case GPUIMAGE_VIGNETTE: [(GPUImageVignetteFilter *)currentlySelectedFilter setVignetteEnd:_currentSliderValue]; break;
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
        case GPUIMAGE_GAUSSIAN: [(GPUImageGaussianBlurFilter *)currentlySelectedFilter setBlurRadiusInPixels:_currentSliderValue]; break;
        case GPUIMAGE_BOXBLUR: [(GPUImageBoxBlurFilter *)currentlySelectedFilter setBlurRadiusInPixels:_currentSliderValue]; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE: [(GPUImageGaussianSelectiveBlurFilter *)currentlySelectedFilter setExcludeCircleRadius:_currentSliderValue]; break;
        case GPUIMAGE_GAUSSIAN_POSITION: [(GPUImageGaussianBlurPositionFilter *)currentlySelectedFilter setBlurRadius:_currentSliderValue]; break;
        case GPUIMAGE_BILATERAL: [(GPUImageBilateralFilter *)currentlySelectedFilter setDistanceNormalizationFactor:_currentSliderValue]; break;
        case GPUIMAGE_MOTIONBLUR: [(GPUImageMotionBlurFilter *)currentlySelectedFilter setBlurAngle:_currentSliderValue]; break;
        case GPUIMAGE_ZOOMBLUR: [(GPUImageZoomBlurFilter *)currentlySelectedFilter setBlurSize:_currentSliderValue]; break;
        case GPUIMAGE_SWIRL: [(GPUImageSwirlFilter *)currentlySelectedFilter setAngle:_currentSliderValue]; break;
        case GPUIMAGE_BULGE: [(GPUImageBulgeDistortionFilter *)currentlySelectedFilter setScale:_currentSliderValue]; break;
        case GPUIMAGE_PINCH: [(GPUImagePinchDistortionFilter *)currentlySelectedFilter setScale:_currentSliderValue]; break;
        case GPUIMAGE_SPHEREREFRACTION: [(GPUImageSphereRefractionFilter *)currentlySelectedFilter setRadius:_currentSliderValue]; break;
        case GPUIMAGE_GLASSSPHERE: [(GPUImageGlassSphereFilter *)currentlySelectedFilter setRadius:_currentSliderValue]; break;
        case GPUIMAGE_PERLINNOISE:  [(GPUImagePerlinNoiseFilter *)currentlySelectedFilter setScale:_currentSliderValue]; break;
        case GPUIMAGE_MOSAIC:  [(GPUImageMosaicFilter *)currentlySelectedFilter setDisplayTileSize:CGSizeMake(_currentSliderValue, _currentSliderValue)]; break;
        case GPUIMAGE_LOCALBINARYPATTERN:
        {
            CGFloat multiplier = _currentSliderValue;
            [(GPUImageLocalBinaryPatternFilter *)currentlySelectedFilter setTexelWidth:(multiplier / self.glView.bounds.size.width)];
            [(GPUImageLocalBinaryPatternFilter *)currentlySelectedFilter setTexelHeight:(multiplier / self.glView.bounds.size.height)];
        }; break;        
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
        case GPUIMAGE_GRAYSCALE: tableRowTitle = @"Grayscale"; break;
        case GPUIMAGE_HISTOGRAM: tableRowTitle = @"Histogram"; break;
        case GPUIMAGE_AVERAGECOLOR: tableRowTitle = @"Average color"; break;
        case GPUIMAGE_LUMINOSITY: tableRowTitle = @"Average luminosity"; break;
        case GPUIMAGE_THRESHOLD: tableRowTitle = @"Threshold"; break;
        case GPUIMAGE_ADAPTIVETHRESHOLD: tableRowTitle = @"Adaptive threshold"; break;
        case GPUIMAGE_AVERAGELUMINANCETHRESHOLD: tableRowTitle = @"Average luminance threshold"; break;
        case GPUIMAGE_PIXELLATE: tableRowTitle = @"Pixellate"; break;
        case GPUIMAGE_POLARPIXELLATE: tableRowTitle = @"Polar pixellation"; break;
        case GPUIMAGE_PIXELLATE_POSITION: tableRowTitle = @"Pixellate (position)"; break;
        case GPUIMAGE_POLKADOT: tableRowTitle = @"Polka dot"; break;
        case GPUIMAGE_HALFTONE: tableRowTitle = @"Halftone"; break;
        case GPUIMAGE_CROSSHATCH: tableRowTitle = @"Crosshatch"; break;
        case GPUIMAGE_SOBELEDGEDETECTION: tableRowTitle = @"Sobel edge detection"; break;
        case GPUIMAGE_PREWITTEDGEDETECTION: tableRowTitle = @"Prewitt edge detection"; break;
        case GPUIMAGE_CANNYEDGEDETECTION: tableRowTitle = @"Canny edge detection"; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION: tableRowTitle = @"Threshold edge detection"; break;
        case GPUIMAGE_HARRISCORNERDETECTION: tableRowTitle = @"Harris corner detector"; break;
        case GPUIMAGE_NOBLECORNERDETECTION: tableRowTitle = @"Noble corner detector"; break;
        case GPUIMAGE_SHITOMASIFEATUREDETECTION: tableRowTitle = @"Shi-Tomasi feature detector"; break;
        case GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR: tableRowTitle = @"Hough transform line detector"; break;
        case GPUIMAGE_BUFFER: tableRowTitle = @"Image buffer"; break;
        case GPUIMAGE_LOWPASS: tableRowTitle = @"Low pass"; break;
        case GPUIMAGE_HIGHPASS: tableRowTitle = @"High pass"; break;
        case GPUIMAGE_MOTIONDETECTOR: tableRowTitle = @"Motion detector"; break;
        case GPUIMAGE_XYGRADIENT: tableRowTitle = @"X-Y gradient"; break;
        case GPUIMAGE_SKETCH: tableRowTitle = @"Sketch"; break;
        case GPUIMAGE_THRESHOLDSKETCH: tableRowTitle = @"Threshold sketch"; break;
        case GPUIMAGE_TOON: tableRowTitle = @"Toon"; break;
        case GPUIMAGE_SMOOTHTOON: tableRowTitle = @"Smooth toon"; break;
        case GPUIMAGE_TILTSHIFT: tableRowTitle = @"Tilt shift"; break;
        case GPUIMAGE_CGA: tableRowTitle = @"CGA colorspace"; break;
        case GPUIMAGE_POSTERIZE: tableRowTitle = @"Posterize"; break;
        case GPUIMAGE_CONVOLUTION: tableRowTitle = @"3x3 convolution"; break;
        case GPUIMAGE_EMBOSS: tableRowTitle = @"Emboss"; break;
        case GPUIMAGE_LAPLACIAN: tableRowTitle = @"Laplacian (3x3)"; break;
        case GPUIMAGE_CHROMAKEYNONBLEND: tableRowTitle = @"Chroma key"; break;
        case GPUIMAGE_KUWAHARA: tableRowTitle = @"Kuwahara"; break;
        case GPUIMAGE_KUWAHARARADIUS3: tableRowTitle = @"Kuwahara (radius 3)"; break;
        case GPUIMAGE_VIGNETTE: tableRowTitle = @"Vignette"; break;
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
        case GPUIMAGE_COLORINVERT: tableRowTitle = @"Color invert"; break;
        case GPUIMAGE_GAUSSIAN: tableRowTitle = @"Gaussian blur"; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE: tableRowTitle = @"Gaussian selective blur"; break;
        case GPUIMAGE_GAUSSIAN_POSITION: tableRowTitle = @"Gaussian (centered)"; break;
        case GPUIMAGE_BOXBLUR: tableRowTitle = @"Box blur"; break;
        case GPUIMAGE_MEDIAN: tableRowTitle = @"Median (3x3)"; break;
        case GPUIMAGE_BILATERAL: tableRowTitle = @"Bilateral blur"; break;
        case GPUIMAGE_MOTIONBLUR: tableRowTitle = @"Motion blur"; break;
        case GPUIMAGE_ZOOMBLUR: tableRowTitle = @"Zoom blur"; break;
        case GPUIMAGE_SWIRL: tableRowTitle = @"Swirl"; break;
        case GPUIMAGE_BULGE: tableRowTitle = @"Bulge"; break;
        case GPUIMAGE_PINCH: tableRowTitle = @"Pinch"; break;
        case GPUIMAGE_SPHEREREFRACTION: tableRowTitle = @"Sphere refraction"; break;
        case GPUIMAGE_GLASSSPHERE: tableRowTitle = @"Glass sphere"; break;
        case GPUIMAGE_STRETCH: tableRowTitle = @"Stretch"; break;
        case GPUIMAGE_DILATION: tableRowTitle = @"Dilation"; break;
        case GPUIMAGE_EROSION: tableRowTitle = @"Erosion"; break;
        case GPUIMAGE_OPENING: tableRowTitle = @"Opening"; break;
        case GPUIMAGE_CLOSING: tableRowTitle = @"Closing"; break;
        case GPUIMAGE_PERLINNOISE: tableRowTitle = @"Perlin noise"; break;
        case GPUIMAGE_VORONOI: tableRowTitle = @"Voronoi"; break;
        case GPUIMAGE_MOSAIC: tableRowTitle = @"Mosaic"; break;
        case GPUIMAGE_LOCALBINARYPATTERN: tableRowTitle = @"Local binary pattern"; break;
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

#import "ShowcaseFilterViewController.h"
#import <CoreImage/CoreImage.h>

@implementation ShowcaseFilterViewController
@synthesize faceDetector;
#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithFilterType:(GPUImageShowcaseFilterType)newFilterType;
{
    self = [super initWithNibName:@"ShowcaseFilterViewController" bundle:nil];
    if (self)
    {
        filterType = newFilterType;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc;
{
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([GPUImageContext supportsFastTextureUpload])
    {
        NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
        self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
        faceThinking = NO;
    }
    
    [self setupFilter];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Note: I needed to stop camera capture before the view went off the screen in order to prevent a crash from the camera still sending frames
    [videoCamera stopCameraCapture];
    
	[super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setupFilter;
{
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
//    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
//    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
//    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    facesSwitch.hidden = YES;
    facesLabel.hidden = YES;
    BOOL needsSecondImage = NO;
    
    switch (filterType)
    {
        case GPUIMAGE_SEPIA:
        {
            self.title = @"Sepia Tone";
            self.filterSettingsSlider.hidden = NO;

            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
            filter = [[GPUImageSepiaFilter alloc] init];
        }; break;
        case GPUIMAGE_PIXELLATE:
        {
            self.title = @"Pixellate";
            self.filterSettingsSlider.hidden = NO;

            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.3];
            
            filter = [[GPUImagePixellateFilter alloc] init];
        }; break;
        case GPUIMAGE_POLARPIXELLATE:
        {
            self.title = @"Polar Pixellate";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:-0.1];
            [self.filterSettingsSlider setMaximumValue:0.1];
            
            filter = [[GPUImagePolarPixellateFilter alloc] init];
        }; break;
        case GPUIMAGE_PIXELLATE_POSITION:
        {
            self.title = @"Pixellate (position)";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.25];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.5];
            
            filter = [[GPUImagePixellatePositionFilter alloc] init];
        }; break;
        case GPUIMAGE_POLKADOT:
        {
            self.title = @"Polka Dot";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.3];
            
            filter = [[GPUImagePolkaDotFilter alloc] init];
        }; break;
        case GPUIMAGE_HALFTONE:
        {
            self.title = @"Halftone";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.01];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.05];
            
            filter = [[GPUImageHalftoneFilter alloc] init];
        }; break;
        case GPUIMAGE_CROSSHATCH:
        {
            self.title = @"Crosshatch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.03];
            [self.filterSettingsSlider setMinimumValue:0.01];
            [self.filterSettingsSlider setMaximumValue:0.06];
            
            filter = [[GPUImageCrosshatchFilter alloc] init];
        }; break;
        case GPUIMAGE_COLORINVERT:
        {
            self.title = @"Color Invert";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageColorInvertFilter alloc] init];
        }; break;
        case GPUIMAGE_GRAYSCALE:
        {
            self.title = @"Grayscale";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageGrayscaleFilter alloc] init];
        }; break;
        case GPUIMAGE_MONOCHROME:
        {
            self.title = @"Monochrome";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
            filter = [[GPUImageMonochromeFilter alloc] init];
            [(GPUImageMonochromeFilter *)filter setColor:(GPUVector4){0.0f, 0.0f, 1.0f, 1.f}];
        }; break;
        case GPUIMAGE_FALSECOLOR:
        {
            self.title = @"False Color";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageFalseColorFilter alloc] init];
		}; break;
        case GPUIMAGE_SOFTELEGANCE:
        {
            self.title = @"Soft Elegance (Lookup)";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageSoftEleganceFilter alloc] init];
        }; break;
        case GPUIMAGE_MISSETIKATE:
        {
            self.title = @"Miss Etikate (Lookup)";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageMissEtikateFilter alloc] init];
        }; break;
        case GPUIMAGE_AMATORKA:
        {
            self.title = @"Amatorka (Lookup)";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageAmatorkaFilter alloc] init];
        }; break;

        case GPUIMAGE_SATURATION:
        {
            self.title = @"Saturation";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            
            filter = [[GPUImageSaturationFilter alloc] init];
        }; break;
        case GPUIMAGE_CONTRAST:
        {
            self.title = @"Contrast";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageContrastFilter alloc] init];
        }; break;
        case GPUIMAGE_BRIGHTNESS:
        {
            self.title = @"Brightness";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageBrightnessFilter alloc] init];
        }; break;
        case GPUIMAGE_LEVELS:
        {
            self.title = @"Levels";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageLevelsFilter alloc] init];
        }; break;
        case GPUIMAGE_RGB:
        {
            self.title = @"RGB";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageRGBFilter alloc] init];
        }; break;
        case GPUIMAGE_HUE:
        {
            self.title = @"Hue";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:360.0];
            [self.filterSettingsSlider setValue:90.0];
            
            filter = [[GPUImageHueFilter alloc] init];
        }; break;
        case GPUIMAGE_WHITEBALANCE:
        {
            self.title = @"White Balance";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:2500.0];
            [self.filterSettingsSlider setMaximumValue:7500.0];
            [self.filterSettingsSlider setValue:5000.0];
            
            filter = [[GPUImageWhiteBalanceFilter alloc] init];
        }; break;
        case GPUIMAGE_EXPOSURE:
        {
            self.title = @"Exposure";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-4.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageExposureFilter alloc] init];
        }; break;
        case GPUIMAGE_SHARPEN:
        {
            self.title = @"Sharpen";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageSharpenFilter alloc] init];
        }; break;
        case GPUIMAGE_UNSHARPMASK:
        {
            self.title = @"Unsharp Mask";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageUnsharpMaskFilter alloc] init];
            
//            [(GPUImageUnsharpMaskFilter *)filter setIntensity:3.0];
        }; break;
        case GPUIMAGE_GAMMA:
        {
            self.title = @"Gamma";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:3.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageGammaFilter alloc] init];
        }; break;
        case GPUIMAGE_TONECURVE:
        {
            self.title = @"Tone curve";
            self.filterSettingsSlider.hidden = NO;

            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];

            filter = [[GPUImageToneCurveFilter alloc] init];
            [(GPUImageToneCurveFilter *)filter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
        }; break;
        case GPUIMAGE_HIGHLIGHTSHADOW:
        {
            self.title = @"Highlights and Shadows";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
            filter = [[GPUImageHighlightShadowFilter alloc] init];
        }; break;
		case GPUIMAGE_HAZE:
        {
            self.title = @"Haze / UV";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-0.2];
            [self.filterSettingsSlider setMaximumValue:0.2];
            [self.filterSettingsSlider setValue:0.2];
            
            filter = [[GPUImageHazeFilter alloc] init];
        }; break;
		case GPUIMAGE_AVERAGECOLOR:
        {
            self.title = @"Average Color";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageAverageColor alloc] init];
        }; break;
		case GPUIMAGE_LUMINOSITY:
        {
            self.title = @"Luminosity";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageLuminosity alloc] init];
        }; break;
		case GPUIMAGE_HISTOGRAM:
        {
            self.title = @"Histogram";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:4.0];
            [self.filterSettingsSlider setMaximumValue:32.0];
            [self.filterSettingsSlider setValue:16.0];
            
            filter = [[GPUImageHistogramFilter alloc] initWithHistogramType:kGPUImageHistogramRGB];
        }; break;
		case GPUIMAGE_THRESHOLD:
        {
            self.title = @"Luminance Threshold";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageLuminanceThresholdFilter alloc] init];
        }; break;
		case GPUIMAGE_ADAPTIVETHRESHOLD:
        {
            self.title = @"Adaptive Threshold";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:20.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        }; break;
		case GPUIMAGE_AVERAGELUMINANCETHRESHOLD:
        {
            self.title = @"Avg. Lum. Threshold";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageAverageLuminanceThresholdFilter alloc] init];
        }; break;
        case GPUIMAGE_CROP:
        {
            self.title = @"Crop";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.2];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0, 0.0, 1.0, 0.25)];
        }; break;
		case GPUIMAGE_MASK:
		{
            self.title = @"Mask";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageMaskFilter alloc] init];
			
			[(GPUImageFilter*)filter setBackgroundColorRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        }; break;
        case GPUIMAGE_TRANSFORM:
        {
            self.title = @"Transform (2-D)";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:6.28];
            [self.filterSettingsSlider setValue:2.0];
            
            filter = [[GPUImageTransformFilter alloc] init];
            [(GPUImageTransformFilter *)filter setAffineTransform:CGAffineTransformMakeRotation(2.0)];
//            [(GPUImageTransformFilter *)filter setIgnoreAspectRatio:YES];
        }; break;
        case GPUIMAGE_TRANSFORM3D:
        {
            self.title = @"Transform (3-D)";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:6.28];
            [self.filterSettingsSlider setValue:0.75];
            
            filter = [[GPUImageTransformFilter alloc] init];
            CATransform3D perspectiveTransform = CATransform3DIdentity;
            perspectiveTransform.m34 = 0.4;
            perspectiveTransform.m33 = 0.4;
            perspectiveTransform = CATransform3DScale(perspectiveTransform, 0.75, 0.75, 0.75);
            perspectiveTransform = CATransform3DRotate(perspectiveTransform, 0.75, 0.0, 1.0, 0.0);
            
            [(GPUImageTransformFilter *)filter setTransform3D:perspectiveTransform];
		}; break;
        case GPUIMAGE_SOBELEDGEDETECTION:
        {
            self.title = @"Sobel Edge Detection";
            self.filterSettingsSlider.hidden = NO;

            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.25];

            filter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_XYGRADIENT:
        {
            self.title = @"XY Derivative";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageXYDerivativeFilter alloc] init];
        }; break;
        case GPUIMAGE_HARRISCORNERDETECTION:
        {
            self.title = @"Harris Corner Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.01];
            [self.filterSettingsSlider setMaximumValue:0.70];
            [self.filterSettingsSlider setValue:0.20];

            filter = [[GPUImageHarrisCornerDetectionFilter alloc] init];
            [(GPUImageHarrisCornerDetectionFilter *)filter setThreshold:0.20];            
        }; break;
        case GPUIMAGE_NOBLECORNERDETECTION:
        {
            self.title = @"Noble Corner Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.01];
            [self.filterSettingsSlider setMaximumValue:0.70];
            [self.filterSettingsSlider setValue:0.20];
            
            filter = [[GPUImageNobleCornerDetectionFilter alloc] init];
            [(GPUImageNobleCornerDetectionFilter *)filter setThreshold:0.20];            
        }; break;
        case GPUIMAGE_SHITOMASIFEATUREDETECTION:
        {
            self.title = @"Shi-Tomasi Feature Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.01];
            [self.filterSettingsSlider setMaximumValue:0.70];
            [self.filterSettingsSlider setValue:0.20];
            
            filter = [[GPUImageShiTomasiFeatureDetectionFilter alloc] init];
            [(GPUImageShiTomasiFeatureDetectionFilter *)filter setThreshold:0.20];            
        }; break;
        case GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR:
        {
            self.title = @"Line Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.2];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.6];
            
            filter = [[GPUImageHoughTransformLineDetector alloc] init];
            [(GPUImageHoughTransformLineDetector *)filter setLineDetectionThreshold:0.60];
        }; break;

        case GPUIMAGE_PREWITTEDGEDETECTION:
        {
            self.title = @"Prewitt Edge Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImagePrewittEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_CANNYEDGEDETECTION:
        {
            self.title = @"Canny Edge Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:1.0];

            filter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION:
        {
            self.title = @"Threshold Edge Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.25];
            
            filter = [[GPUImageThresholdEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_LOCALBINARYPATTERN:
        {
            self.title = @"Local Binary Pattern";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageLocalBinaryPatternFilter alloc] init];
        }; break;
        case GPUIMAGE_BUFFER:
        {
            self.title = @"Image Buffer";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageBuffer alloc] init];
        }; break;
        case GPUIMAGE_LOWPASS:
        {
            self.title = @"Low Pass";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageLowPassFilter alloc] init];
        }; break;
        case GPUIMAGE_HIGHPASS:
        {
            self.title = @"High Pass";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageHighPassFilter alloc] init];
        }; break;
        case GPUIMAGE_MOTIONDETECTOR:
        {
            [videoCamera rotateCamera];

            self.title = @"Motion Detector";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageMotionDetector alloc] init];
        }; break;
        case GPUIMAGE_SKETCH:
        {
            self.title = @"Sketch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.25];
            
            filter = [[GPUImageSketchFilter alloc] init];
        }; break;
        case GPUIMAGE_THRESHOLDSKETCH:
        {
            self.title = @"Threshold Sketch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.25];
            
            filter = [[GPUImageThresholdSketchFilter alloc] init];
        }; break;
        case GPUIMAGE_TOON:
        {
            self.title = @"Toon";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageToonFilter alloc] init];
        }; break;            
        case GPUIMAGE_SMOOTHTOON:
        {
            self.title = @"Smooth Toon";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:6.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageSmoothToonFilter alloc] init];
        }; break;            
        case GPUIMAGE_TILTSHIFT:
        {
            self.title = @"Tilt Shift";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.2];
            [self.filterSettingsSlider setMaximumValue:0.8];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageTiltShiftFilter alloc] init];
            [(GPUImageTiltShiftFilter *)filter setTopFocusLevel:0.4];
            [(GPUImageTiltShiftFilter *)filter setBottomFocusLevel:0.6];
            [(GPUImageTiltShiftFilter *)filter setFocusFallOffRate:0.2];
        }; break;
        case GPUIMAGE_CGA:
        {
            self.title = @"CGA Colorspace";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageCGAColorspaceFilter alloc] init];
        }; break;
        case GPUIMAGE_CONVOLUTION:
        {
            self.title = @"3x3 Convolution";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImage3x3ConvolutionFilter alloc] init];
//            [(GPUImage3x3ConvolutionFilter *)filter setConvolutionKernel:(GPUMatrix3x3){
//                {-2.0f, -1.0f, 0.0f},
//                {-1.0f,  1.0f, 1.0f},
//                { 0.0f,  1.0f, 2.0f}
//            }];
            [(GPUImage3x3ConvolutionFilter *)filter setConvolutionKernel:(GPUMatrix3x3){
                {-1.0f,  0.0f, 1.0f},
                {-2.0f, 0.0f, 2.0f},
                {-1.0f,  0.0f, 1.0f}
            }];

//            [(GPUImage3x3ConvolutionFilter *)filter setConvolutionKernel:(GPUMatrix3x3){
//                {1.0f,  1.0f, 1.0f},
//                {1.0f, -8.0f, 1.0f},
//                {1.0f,  1.0f, 1.0f}
//            }];
//            [(GPUImage3x3ConvolutionFilter *)filter setConvolutionKernel:(GPUMatrix3x3){
//                { 0.11f,  0.11f, 0.11f},
//                { 0.11f,  0.11f, 0.11f},
//                { 0.11f,  0.11f, 0.11f}
//            }];
        }; break;
        case GPUIMAGE_EMBOSS:
        {
            self.title = @"Emboss";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageEmbossFilter alloc] init];
        }; break;
        case GPUIMAGE_LAPLACIAN:
        {
            self.title = @"Laplacian";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageLaplacianFilter alloc] init];
        }; break;
        case GPUIMAGE_POSTERIZE:
        {
            self.title = @"Posterize";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:20.0];
            [self.filterSettingsSlider setValue:10.0];
            
            filter = [[GPUImagePosterizeFilter alloc] init];
        }; break;
        case GPUIMAGE_SWIRL:
        {
            self.title = @"Swirl";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageSwirlFilter alloc] init];
        }; break;
        case GPUIMAGE_BULGE:
        {
            self.title = @"Bulge";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageBulgeDistortionFilter alloc] init];
        }; break;
        case GPUIMAGE_SPHEREREFRACTION:
        {
            self.title = @"Sphere Refraction";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.15];
            
            filter = [[GPUImageSphereRefractionFilter alloc] init];
            [(GPUImageSphereRefractionFilter *)filter setRadius:0.15];
        }; break;
        case GPUIMAGE_GLASSSPHERE:
        {
            self.title = @"Glass Sphere";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.15];
            
            filter = [[GPUImageGlassSphereFilter alloc] init];
            [(GPUImageGlassSphereFilter *)filter setRadius:0.15];
        }; break;
        case GPUIMAGE_PINCH:
        {
            self.title = @"Pinch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-2.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImagePinchDistortionFilter alloc] init];
        }; break;
        case GPUIMAGE_STRETCH:
        {
            self.title = @"Stretch";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageStretchDistortionFilter alloc] init];
        }; break;
        case GPUIMAGE_DILATION:
        {
            self.title = @"Dilation";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageRGBDilationFilter alloc] initWithRadius:4];
		}; break;
        case GPUIMAGE_EROSION:
        {
            self.title = @"Erosion";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageRGBErosionFilter alloc] initWithRadius:4];
		}; break;
        case GPUIMAGE_OPENING:
        {
            self.title = @"Opening";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageRGBOpeningFilter alloc] initWithRadius:4];
		}; break;
        case GPUIMAGE_CLOSING:
        {
            self.title = @"Closing";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageRGBClosingFilter alloc] initWithRadius:4];
		}; break;

        case GPUIMAGE_PERLINNOISE:
        {
            self.title = @"Perlin Noise";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:30.0];
            [self.filterSettingsSlider setValue:8.0];
            
            filter = [[GPUImagePerlinNoiseFilter alloc] init];
        }; break;
        case GPUIMAGE_VORONOI:
        {
            self.title = @"Voronoi";
            self.filterSettingsSlider.hidden = YES;
            
            GPUImageJFAVoronoiFilter *jfa = [[GPUImageJFAVoronoiFilter alloc] init];
            [jfa setSizeInPixels:CGSizeMake(1024.0, 1024.0)];
            
            sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"voroni_points2.png"]];

            [sourcePicture addTarget:jfa];
            
            filter = [[GPUImageVoronoiConsumerFilter alloc] init];
            
            [jfa setSizeInPixels:CGSizeMake(1024.0, 1024.0)];
            [(GPUImageVoronoiConsumerFilter *)filter setSizeInPixels:CGSizeMake(1024.0, 1024.0)];
            
            [videoCamera addTarget:filter];
            [jfa addTarget:filter];
            [sourcePicture processImage];
        }; break;
        case GPUIMAGE_MOSAIC:
        {
            self.title = @"Mosaic";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.002];
            [self.filterSettingsSlider setMaximumValue:0.05];
            [self.filterSettingsSlider setValue:0.025];
            
            filter = [[GPUImageMosaicFilter alloc] init];
            [(GPUImageMosaicFilter *)filter setTileSet:@"squares.png"];
            [(GPUImageMosaicFilter *)filter setColorOn:NO];
            //[(GPUImageMosaicFilter *)filter setTileSet:@"dotletterstiles.png"];
            //[(GPUImageMosaicFilter *)filter setTileSet:@"curvies.png"]; 
                        
        }; break;
        case GPUIMAGE_CHROMAKEY:
        {
            self.title = @"Chroma Key (Green)";
            self.filterSettingsSlider.hidden = NO;
            needsSecondImage = YES;	
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.4];
            
            filter = [[GPUImageChromaKeyBlendFilter alloc] init];
            [(GPUImageChromaKeyBlendFilter *)filter setColorToReplaceRed:0.0 green:1.0 blue:0.0];
        }; break;
        case GPUIMAGE_CHROMAKEYNONBLEND:
        {
            self.title = @"Chroma Key (Green)";
            self.filterSettingsSlider.hidden = NO;
            needsSecondImage = YES;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.4];
            
            filter = [[GPUImageChromaKeyFilter alloc] init];
            [(GPUImageChromaKeyFilter *)filter setColorToReplaceRed:0.0 green:1.0 blue:0.0];
        }; break;
        case GPUIMAGE_ADD:
        {
            self.title = @"Add Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;
            
            filter = [[GPUImageAddBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_DIVIDE:
        {
            self.title = @"Divide Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;
            
            filter = [[GPUImageDivideBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_MULTIPLY:
        {
            self.title = @"Multiply Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageMultiplyBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_OVERLAY:
        {
            self.title = @"Overlay Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageOverlayBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_LIGHTEN:
        {
            self.title = @"Lighten Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageLightenBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_DARKEN:
        {
            self.title = @"Darken Blend";
            self.filterSettingsSlider.hidden = YES;
            
            needsSecondImage = YES;	
            filter = [[GPUImageDarkenBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_DISSOLVE:
        {
            self.title = @"Dissolve Blend";
            self.filterSettingsSlider.hidden = NO;
            needsSecondImage = YES;	
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageDissolveBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_SCREENBLEND:
        {
            self.title = @"Screen Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageScreenBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_COLORBURN:
        {
            self.title = @"Color Burn Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageColorBurnBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_COLORDODGE:
        {
            self.title = @"Color Dodge Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageColorDodgeBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_LINEARBURN:
        {
            self.title = @"Linear Burn Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;
            
            filter = [[GPUImageLinearBurnBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_EXCLUSIONBLEND:
        {
            self.title = @"Exclusion Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageExclusionBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_DIFFERENCEBLEND:
        {
            self.title = @"Difference Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageDifferenceBlendFilter alloc] init];
        }; break;
		case GPUIMAGE_SUBTRACTBLEND:
        {
            self.title = @"Subtract Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageSubtractBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_HARDLIGHTBLEND:
        {
            self.title = @"Hard Light Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageHardLightBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_SOFTLIGHTBLEND:
        {
            self.title = @"Soft Light Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;	
            
            filter = [[GPUImageSoftLightBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_COLORBLEND:
        {
            self.title = @"Color Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;
            
            filter = [[GPUImageColorBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_HUEBLEND:
        {
            self.title = @"Hue Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;
            
            filter = [[GPUImageHueBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_SATURATIONBLEND:
        {
            self.title = @"Saturation Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;
            
            filter = [[GPUImageSaturationBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_LUMINOSITYBLEND:
        {
            self.title = @"Luminosity Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;
            
            filter = [[GPUImageLuminosityBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_NORMALBLEND:
        {
            self.title = @"Normal Blend";
            self.filterSettingsSlider.hidden = YES;
            needsSecondImage = YES;
            
            filter = [[GPUImageNormalBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_POISSONBLEND:
        {
            self.title = @"Poisson Blend";
            self.filterSettingsSlider.hidden = NO;
            needsSecondImage = YES;

            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];

            filter = [[GPUImagePoissonBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_OPACITY:
        {
            self.title = @"Opacity Adjustment";
            self.filterSettingsSlider.hidden = NO;
            needsSecondImage = YES;	
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
            filter = [[GPUImageOpacityFilter alloc] init];
        }; break;
        case GPUIMAGE_CUSTOM:
        {
            self.title = @"Custom";
            self.filterSettingsSlider.hidden = YES;

            filter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"CustomFilter"];
        }; break;
        case GPUIMAGE_KUWAHARA:
        {
            self.title = @"Kuwahara";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:3.0];
            [self.filterSettingsSlider setMaximumValue:8.0];
            [self.filterSettingsSlider setValue:3.0];
            
            filter = [[GPUImageKuwaharaFilter alloc] init];
        }; break;
        case GPUIMAGE_KUWAHARARADIUS3:
        {
            self.title = @"Kuwahara (Radius 3)";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageKuwaharaRadius3Filter alloc] init];
        }; break;
        case GPUIMAGE_VIGNETTE:
        {
             self.title = @"Vignette";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.5];
            [self.filterSettingsSlider setMaximumValue:0.9];
            [self.filterSettingsSlider setValue:0.75];
            
            filter = [[GPUImageVignetteFilter alloc] init];
        }; break;
        case GPUIMAGE_GAUSSIAN:
        {
            self.title = @"Gaussian Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:24.0];
            [self.filterSettingsSlider setValue:2.0];
            
            filter = [[GPUImageGaussianBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_BOXBLUR:
        {
            self.title = @"Box Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:24.0];
            [self.filterSettingsSlider setValue:2.0];
            
            filter = [[GPUImageBoxBlurFilter alloc] init];
		}; break;
        case GPUIMAGE_MEDIAN:
        {
            self.title = @"Median";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageMedianFilter alloc] init];
		}; break;
        case GPUIMAGE_MOTIONBLUR:
        {
            self.title = @"Motion Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:180.0f];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageMotionBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_ZOOMBLUR:
        {
            self.title = @"Zoom Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.5f];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageZoomBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_IOSBLUR:
        {
            self.title = @"iOS 7 Blur";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageiOSBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_UIELEMENT:
        {
            self.title = @"UI Element";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageSepiaFilter alloc] init];
		}; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE:
        {
            self.title = @"Selective Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:.75f];
            [self.filterSettingsSlider setValue:40.0/320.0];
            
            filter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            [(GPUImageGaussianSelectiveBlurFilter*)filter setExcludeCircleRadius:40.0/320.0];
        }; break;
        case GPUIMAGE_GAUSSIAN_POSITION:
        {
            self.title = @"Selective Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:.75f];
            [self.filterSettingsSlider setValue:40.0/320.0];
            
            filter = [[GPUImageGaussianBlurPositionFilter alloc] init];
            [(GPUImageGaussianBlurPositionFilter*)filter setBlurRadius:40.0/320.0];
        }; break;
        case GPUIMAGE_BILATERAL:
        {
            self.title = @"Bilateral Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:10.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageBilateralFilter alloc] init];
        }; break;
        case GPUIMAGE_FILTERGROUP:
        {
            self.title = @"Filter Group";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.3];
            
            filter = [[GPUImageFilterGroup alloc] init];
            
            GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
            [(GPUImageFilterGroup *)filter addFilter:sepiaFilter];

            GPUImagePixellateFilter *pixellateFilter = [[GPUImagePixellateFilter alloc] init];
            [(GPUImageFilterGroup *)filter addFilter:pixellateFilter];
            
            [sepiaFilter addTarget:pixellateFilter];
            [(GPUImageFilterGroup *)filter setInitialFilters:[NSArray arrayWithObject:sepiaFilter]];
            [(GPUImageFilterGroup *)filter setTerminalFilter:pixellateFilter];
        }; break;

        case GPUIMAGE_FACES:
        {
            facesSwitch.hidden = NO;
            facesLabel.hidden = NO;

            [videoCamera rotateCamera];
            self.title = @"Face Detection";
            self.filterSettingsSlider.hidden = YES;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            
            filter = [[GPUImageSaturationFilter alloc] init];
            [videoCamera setDelegate:self];
            break;
        }
            
        default: filter = [[GPUImageSepiaFilter alloc] init]; break;
    }
    
    if (filterType == GPUIMAGE_FILECONFIG)
    {
        self.title = @"File Configuration";
        pipeline = [[GPUImageFilterPipeline alloc] initWithConfigurationFile:[[NSBundle mainBundle] URLForResource:@"SampleConfiguration" withExtension:@"plist"]
                                                                                               input:videoCamera output:(GPUImageView*)self.view];
        
//        [pipeline addFilter:rotationFilter atIndex:0];
    } 
    else 
    {
    
        if (filterType != GPUIMAGE_VORONOI)
        {
            [videoCamera addTarget:filter];
        }
        
        videoCamera.runBenchmark = YES;
        GPUImageView *filterView = (GPUImageView *)self.view;
        
        if (needsSecondImage)
        {
			UIImage *inputImage;
			
			if (filterType == GPUIMAGE_MASK) 
			{
				inputImage = [UIImage imageNamed:@"mask"];
			}
            /*
			else if (filterType == GPUIMAGE_VORONOI) {
                inputImage = [UIImage imageNamed:@"voroni_points.png"];
            }*/
            else {
				// The picture is only used for two-image blend filters
				inputImage = [UIImage imageNamed:@"WID-small.jpg"];
			}
			
//            sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:NO];
            sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
            [sourcePicture processImage];
            [sourcePicture addTarget:filter];
        }

        
        if (filterType == GPUIMAGE_HISTOGRAM)
        {
            // I'm adding an intermediary filter because glReadPixels() requires something to be rendered for its glReadPixels() operation to work
            [videoCamera removeTarget:filter];
            GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
            [videoCamera addTarget:gammaFilter];
            [gammaFilter addTarget:filter];

            GPUImageHistogramGenerator *histogramGraph = [[GPUImageHistogramGenerator alloc] init];
            
            [histogramGraph forceProcessingAtSize:CGSizeMake(256.0, 330.0)];
            [filter addTarget:histogramGraph];
            
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            blendFilter.mix = 0.75;            
            [blendFilter forceProcessingAtSize:CGSizeMake(256.0, 330.0)];
            
            [videoCamera addTarget:blendFilter];
            [histogramGraph addTarget:blendFilter];

            [blendFilter addTarget:filterView];
        }
        else if ( (filterType == GPUIMAGE_HARRISCORNERDETECTION) || (filterType == GPUIMAGE_NOBLECORNERDETECTION) || (filterType == GPUIMAGE_SHITOMASIFEATUREDETECTION) )
        {
            GPUImageCrosshairGenerator *crosshairGenerator = [[GPUImageCrosshairGenerator alloc] init];
            crosshairGenerator.crosshairWidth = 15.0;
            [crosshairGenerator forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
            
            [(GPUImageHarrisCornerDetectionFilter *)filter setCornersDetectedBlock:^(GLfloat* cornerArray, NSUInteger cornersDetected, CMTime frameTime) {
                [crosshairGenerator renderCrosshairsFromArray:cornerArray count:cornersDetected frameTime:frameTime];
            }];

            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            [blendFilter forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
            GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
            [videoCamera addTarget:gammaFilter];
            [gammaFilter addTarget:blendFilter];

            [crosshairGenerator addTarget:blendFilter];

            [blendFilter addTarget:filterView];
        }
        else if (filterType == GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR)
        {
            GPUImageLineGenerator *lineGenerator = [[GPUImageLineGenerator alloc] init];
//            lineGenerator.crosshairWidth = 15.0;
            [lineGenerator forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
            [lineGenerator setLineColorRed:1.0 green:0.0 blue:0.0];
            [(GPUImageHoughTransformLineDetector *)filter setLinesDetectedBlock:^(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime){
                [lineGenerator renderLinesFromArray:lineArray count:linesDetected frameTime:frameTime];
            }];
            
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            [blendFilter forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
            GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
            [videoCamera addTarget:gammaFilter];
            [gammaFilter addTarget:blendFilter];
            
            [lineGenerator addTarget:blendFilter];
            
            [blendFilter addTarget:filterView];
        }
        else if (filterType == GPUIMAGE_UIELEMENT)
        {
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            blendFilter.mix = 1.0;
            
            NSDate *startTime = [NSDate date];
            
            UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 240.0f, 320.0f)];
            timeLabel.font = [UIFont systemFontOfSize:17.0f];
            timeLabel.text = @"Time: 0.0 s";
            timeLabel.textAlignment = UITextAlignmentCenter;
            timeLabel.backgroundColor = [UIColor clearColor];
            timeLabel.textColor = [UIColor whiteColor];

            uiElementInput = [[GPUImageUIElement alloc] initWithView:timeLabel];
            
            [filter addTarget:blendFilter];
            [uiElementInput addTarget:blendFilter];
            
            [blendFilter addTarget:filterView];

            __unsafe_unretained GPUImageUIElement *weakUIElementInput = uiElementInput;
            
            [filter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime){
                timeLabel.text = [NSString stringWithFormat:@"Time: %f s", -[startTime timeIntervalSinceNow]];
                [weakUIElementInput update];
            }];
        }
        else if (filterType == GPUIMAGE_BUFFER)
        {
            GPUImageDifferenceBlendFilter *blendFilter = [[GPUImageDifferenceBlendFilter alloc] init];

            [videoCamera removeTarget:filter];

            GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
            [videoCamera addTarget:gammaFilter];
            [gammaFilter addTarget:blendFilter];
            [videoCamera addTarget:filter];

            [filter addTarget:blendFilter];
            
            [blendFilter addTarget:filterView];
        }
        else if ( (filterType == GPUIMAGE_OPACITY) || (filterType == GPUIMAGE_CHROMAKEYNONBLEND) )
        {
            [sourcePicture removeTarget:filter];
            [videoCamera removeTarget:filter];
            [videoCamera addTarget:filter];
            
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            blendFilter.mix = 1.0;
            [sourcePicture addTarget:blendFilter];
            [filter addTarget:blendFilter];
            
            [blendFilter addTarget:filterView];
        }
        else if ( (filterType == GPUIMAGE_SPHEREREFRACTION) || (filterType == GPUIMAGE_GLASSSPHERE) )
        {
            // Provide a blurred image for a cool-looking background
            GPUImageGaussianBlurFilter *gaussianBlur = [[GPUImageGaussianBlurFilter alloc] init];
            [videoCamera addTarget:gaussianBlur];
            gaussianBlur.blurRadiusInPixels = 5.0;

            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            blendFilter.mix = 1.0;
            [gaussianBlur addTarget:blendFilter];
            [filter addTarget:blendFilter];
            
            [blendFilter addTarget:filterView];

        }
        else if (filterType == GPUIMAGE_AVERAGECOLOR)
        {
            GPUImageSolidColorGenerator *colorGenerator = [[GPUImageSolidColorGenerator alloc] init];
            [colorGenerator forceProcessingAtSize:[filterView sizeInPixels]];
            
            [(GPUImageAverageColor *)filter setColorAverageProcessingFinishedBlock:^(CGFloat redComponent, CGFloat greenComponent, CGFloat blueComponent, CGFloat alphaComponent, CMTime frameTime) {
                [colorGenerator setColorRed:redComponent green:greenComponent blue:blueComponent alpha:alphaComponent];
//                NSLog(@"Average color: %f, %f, %f, %f", redComponent, greenComponent, blueComponent, alphaComponent);
            }];
            
            [colorGenerator addTarget:filterView];
        }
        else if (filterType == GPUIMAGE_LUMINOSITY)
        {
            GPUImageSolidColorGenerator *colorGenerator = [[GPUImageSolidColorGenerator alloc] init];
            [colorGenerator forceProcessingAtSize:[filterView sizeInPixels]];
            
            [(GPUImageLuminosity *)filter setLuminosityProcessingFinishedBlock:^(CGFloat luminosity, CMTime frameTime) {
                [colorGenerator setColorRed:luminosity green:luminosity blue:luminosity alpha:1.0];
            }];
            
            [colorGenerator addTarget:filterView];
        }
        else if (filterType == GPUIMAGE_IOSBLUR)
        {
            [videoCamera removeAllTargets];
            [videoCamera addTarget:filterView];
            GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] init];
            cropFilter.cropRegion = CGRectMake(0.0, 0.5, 1.0, 0.5);
            [videoCamera addTarget:cropFilter];
            [cropFilter addTarget:filter];
            
            CGRect currentViewFrame = filterView.bounds;
            GPUImageView *blurOverlayView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, round(currentViewFrame.size.height / 2.0), currentViewFrame.size.width, currentViewFrame.size.height - round(currentViewFrame.size.height / 2.0))];
            [filterView addSubview:blurOverlayView];
            [filter addTarget:blurOverlayView];
        }
        else if (filterType == GPUIMAGE_MOTIONDETECTOR)
        {
            faceView = [[UIView alloc] initWithFrame:CGRectMake(100.0, 100.0, 100.0, 100.0)];
            faceView.layer.borderWidth = 1;
            faceView.layer.borderColor = [[UIColor redColor] CGColor];
            [self.view addSubview:faceView];
            faceView.hidden = YES;
            
            __unsafe_unretained ShowcaseFilterViewController * weakSelf = self;
            [(GPUImageMotionDetector *) filter setMotionDetectionBlock:^(CGPoint motionCentroid, CGFloat motionIntensity, CMTime frameTime) {
                if (motionIntensity > 0.01)
                {
                    CGFloat motionBoxWidth = 1500.0 * motionIntensity;
                    CGSize viewBounds = weakSelf.view.bounds.size;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf->faceView.frame = CGRectMake(round(viewBounds.width * motionCentroid.x - motionBoxWidth / 2.0), round(viewBounds.height * motionCentroid.y - motionBoxWidth / 2.0), motionBoxWidth, motionBoxWidth);
                        weakSelf->faceView.hidden = NO;
                    });
                    
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf->faceView.hidden = YES;
                    });
                }
                
            }];
            
            [videoCamera addTarget:filterView];
        }
        else
        {
            [filter addTarget:filterView];
        }
    } 

    [videoCamera startCameraCapture];
}

#pragma mark -
#pragma mark Filter adjustments

- (IBAction)updateFilterFromSlider:(id)sender;
{
    [videoCamera resetBenchmarkAverage];
    switch(filterType)
    {
        case GPUIMAGE_SEPIA: [(GPUImageSepiaFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PIXELLATE: [(GPUImagePixellateFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_POLARPIXELLATE: [(GPUImagePolarPixellateFilter *)filter setPixelSize:CGSizeMake([(UISlider *)sender value], [(UISlider *)sender value])]; break;
        case GPUIMAGE_PIXELLATE_POSITION: [(GPUImagePixellatePositionFilter *)filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_POLKADOT: [(GPUImagePolkaDotFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HALFTONE: [(GPUImageHalftoneFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SATURATION: [(GPUImageSaturationFilter *)filter setSaturation:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CONTRAST: [(GPUImageContrastFilter *)filter setContrast:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BRIGHTNESS: [(GPUImageBrightnessFilter *)filter setBrightness:[(UISlider *)sender value]]; break;
        case GPUIMAGE_LEVELS: {
            float value = [(UISlider *)sender value];
            [(GPUImageLevelsFilter *)filter setRedMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            [(GPUImageLevelsFilter *)filter setGreenMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            [(GPUImageLevelsFilter *)filter setBlueMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
        }; break;
        case GPUIMAGE_EXPOSURE: [(GPUImageExposureFilter *)filter setExposure:[(UISlider *)sender value]]; break;
        case GPUIMAGE_MONOCHROME: [(GPUImageMonochromeFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_RGB: [(GPUImageRGBFilter *)filter setGreen:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HUE: [(GPUImageHueFilter *)filter setHue:[(UISlider *)sender value]]; break;
        case GPUIMAGE_WHITEBALANCE: [(GPUImageWhiteBalanceFilter *)filter setTemperature:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SHARPEN: [(GPUImageSharpenFilter *)filter setSharpness:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HISTOGRAM: [(GPUImageHistogramFilter *)filter setDownsamplingFactor:round([(UISlider *)sender value])]; break;
        case GPUIMAGE_UNSHARPMASK: [(GPUImageUnsharpMaskFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
//        case GPUIMAGE_UNSHARPMASK: [(GPUImageUnsharpMaskFilter *)filter setBlurSize:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GAMMA: [(GPUImageGammaFilter *)filter setGamma:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CROSSHATCH: [(GPUImageCrosshatchFilter *)filter setCrossHatchSpacing:[(UISlider *)sender value]]; break;
        case GPUIMAGE_POSTERIZE: [(GPUImagePosterizeFilter *)filter setColorLevels:round([(UISlider*)sender value])]; break;
        case GPUIMAGE_HAZE: [(GPUImageHazeFilter *)filter setDistance:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SOBELEDGEDETECTION: [(GPUImageSobelEdgeDetectionFilter *)filter setEdgeStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PREWITTEDGEDETECTION: [(GPUImagePrewittEdgeDetectionFilter *)filter setEdgeStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SKETCH: [(GPUImageSketchFilter *)filter setEdgeStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_THRESHOLD: [(GPUImageLuminanceThresholdFilter *)filter setThreshold:[(UISlider *)sender value]]; break;
        case GPUIMAGE_ADAPTIVETHRESHOLD: [(GPUImageAdaptiveThresholdFilter *)filter setBlurRadiusInPixels:[(UISlider*)sender value]]; break;
        case GPUIMAGE_AVERAGELUMINANCETHRESHOLD: [(GPUImageAverageLuminanceThresholdFilter *)filter setThresholdMultiplier:[(UISlider *)sender value]]; break;
        case GPUIMAGE_DISSOLVE: [(GPUImageDissolveBlendFilter *)filter setMix:[(UISlider *)sender value]]; break;
        case GPUIMAGE_POISSONBLEND: [(GPUImagePoissonBlendFilter *)filter setMix:[(UISlider *)sender value]]; break;
        case GPUIMAGE_LOWPASS: [(GPUImageLowPassFilter *)filter setFilterStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HIGHPASS: [(GPUImageHighPassFilter *)filter setFilterStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_MOTIONDETECTOR: [(GPUImageMotionDetector *)filter setLowPassFilterStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CHROMAKEY: [(GPUImageChromaKeyBlendFilter *)filter setThresholdSensitivity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CHROMAKEYNONBLEND: [(GPUImageChromaKeyFilter *)filter setThresholdSensitivity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_KUWAHARA: [(GPUImageKuwaharaFilter *)filter setRadius:round([(UISlider *)sender value])]; break;
        case GPUIMAGE_SWIRL: [(GPUImageSwirlFilter *)filter setAngle:[(UISlider *)sender value]]; break;
        case GPUIMAGE_EMBOSS: [(GPUImageEmbossFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CANNYEDGEDETECTION: [(GPUImageCannyEdgeDetectionFilter *)filter setBlurTexelSpacingMultiplier:[(UISlider*)sender value]]; break;
//        case GPUIMAGE_CANNYEDGEDETECTION: [(GPUImageCannyEdgeDetectionFilter *)filter setLowerThreshold:[(UISlider*)sender value]]; break;
        case GPUIMAGE_HARRISCORNERDETECTION: [(GPUImageHarrisCornerDetectionFilter *)filter setThreshold:[(UISlider*)sender value]]; break;
        case GPUIMAGE_NOBLECORNERDETECTION: [(GPUImageNobleCornerDetectionFilter *)filter setThreshold:[(UISlider*)sender value]]; break;
        case GPUIMAGE_SHITOMASIFEATUREDETECTION: [(GPUImageShiTomasiFeatureDetectionFilter *)filter setThreshold:[(UISlider*)sender value]]; break;
        case GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR: [(GPUImageHoughTransformLineDetector *)filter setLineDetectionThreshold:[(UISlider*)sender value]]; break;
//        case GPUIMAGE_HARRISCORNERDETECTION: [(GPUImageHarrisCornerDetectionFilter *)filter setSensitivity:[(UISlider*)sender value]]; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION: [(GPUImageThresholdEdgeDetectionFilter *)filter setThreshold:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SMOOTHTOON: [(GPUImageSmoothToonFilter *)filter setBlurRadiusInPixels:[(UISlider*)sender value]]; break;
        case GPUIMAGE_THRESHOLDSKETCH: [(GPUImageThresholdSketchFilter *)filter setThreshold:[(UISlider *)sender value]]; break;
//        case GPUIMAGE_BULGE: [(GPUImageBulgeDistortionFilter *)filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BULGE: [(GPUImageBulgeDistortionFilter *)filter setScale:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SPHEREREFRACTION: [(GPUImageSphereRefractionFilter *)filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GLASSSPHERE: [(GPUImageGlassSphereFilter *)filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_TONECURVE: [(GPUImageToneCurveFilter *)filter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, [(UISlider *)sender value])], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]]; break;
        case GPUIMAGE_HIGHLIGHTSHADOW: [(GPUImageHighlightShadowFilter *)filter setHighlights:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PINCH: [(GPUImagePinchDistortionFilter *)filter setScale:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PERLINNOISE:  [(GPUImagePerlinNoiseFilter *)filter setScale:[(UISlider *)sender value]]; break;
        case GPUIMAGE_MOSAIC:  [(GPUImageMosaicFilter *)filter setDisplayTileSize:CGSizeMake([(UISlider *)sender value], [(UISlider *)sender value])]; break;
        case GPUIMAGE_VIGNETTE: [(GPUImageVignetteFilter *)filter setVignetteEnd:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BOXBLUR: [(GPUImageBoxBlurFilter *)filter setBlurRadiusInPixels:[(UISlider*)sender value]]; break;
        case GPUIMAGE_GAUSSIAN: [(GPUImageGaussianBlurFilter *)filter setBlurRadiusInPixels:[(UISlider*)sender value]]; break;
//        case GPUIMAGE_GAUSSIAN: [(GPUImageGaussianBlurFilter *)filter setBlurPasses:round([(UISlider*)sender value])]; break;
//        case GPUIMAGE_BILATERAL: [(GPUImageBilateralFilter *)filter setBlurSize:[(UISlider*)sender value]]; break;
        case GPUIMAGE_BILATERAL: [(GPUImageBilateralFilter *)filter setDistanceNormalizationFactor:[(UISlider*)sender value]]; break;
        case GPUIMAGE_MOTIONBLUR: [(GPUImageMotionBlurFilter *)filter setBlurAngle:[(UISlider*)sender value]]; break;
        case GPUIMAGE_ZOOMBLUR: [(GPUImageZoomBlurFilter *)filter setBlurSize:[(UISlider*)sender value]]; break;
        case GPUIMAGE_OPACITY:  [(GPUImageOpacityFilter *)filter setOpacity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE: [(GPUImageGaussianSelectiveBlurFilter *)filter setExcludeCircleRadius:[(UISlider*)sender value]]; break;
        case GPUIMAGE_GAUSSIAN_POSITION: [(GPUImageGaussianBlurPositionFilter *)filter setBlurRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_FILTERGROUP: [(GPUImagePixellateFilter *)[(GPUImageFilterGroup *)filter filterAtIndex:1] setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CROP: [(GPUImageCropFilter *)filter setCropRegion:CGRectMake(0.0, 0.0, 1.0, [(UISlider*)sender value])]; break;
        case GPUIMAGE_TRANSFORM: [(GPUImageTransformFilter *)filter setAffineTransform:CGAffineTransformMakeRotation([(UISlider*)sender value])]; break;
        case GPUIMAGE_TRANSFORM3D:
        {
            CATransform3D perspectiveTransform = CATransform3DIdentity;
            perspectiveTransform.m34 = 0.4;
            perspectiveTransform.m33 = 0.4;
            perspectiveTransform = CATransform3DScale(perspectiveTransform, 0.75, 0.75, 0.75);
            perspectiveTransform = CATransform3DRotate(perspectiveTransform, [(UISlider*)sender value], 0.0, 1.0, 0.0);

            [(GPUImageTransformFilter *)filter setTransform3D:perspectiveTransform];            
        }; break;
        case GPUIMAGE_TILTSHIFT:
        {
            CGFloat midpoint = [(UISlider *)sender value];
            [(GPUImageTiltShiftFilter *)filter setTopFocusLevel:midpoint - 0.1];
            [(GPUImageTiltShiftFilter *)filter setBottomFocusLevel:midpoint + 0.1];
        }; break;
        case GPUIMAGE_LOCALBINARYPATTERN:
        {
            CGFloat multiplier = [(UISlider *)sender value];
            [(GPUImageLocalBinaryPatternFilter *)filter setTexelWidth:(multiplier / self.view.bounds.size.width)];
            [(GPUImageLocalBinaryPatternFilter *)filter setTexelHeight:(multiplier / self.view.bounds.size.height)];
        }; break;
        default: break;
    }
}

#pragma mark - Face Detection Delegate Callback
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (!faceThinking) {
        CFAllocatorRef allocator = CFAllocatorGetDefault();
        CMSampleBufferRef sbufCopyOut;
        CMSampleBufferCreateCopy(allocator,sampleBuffer,&sbufCopyOut);
        [self performSelectorInBackground:@selector(grepFacesForSampleBuffer:) withObject:CFBridgingRelease(sbufCopyOut)];
    }
}

- (void)grepFacesForSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    faceThinking = TRUE;
    NSLog(@"Faces thinking");
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *convertedImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
    
	if (attachments)
		CFRelease(attachments);
	NSDictionary *imageOptions = nil;
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	int exifOrientation;
	
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
	};
	BOOL isUsingFrontFacingCamera = FALSE;
    AVCaptureDevicePosition currentCameraPosition = [videoCamera cameraPosition];
    
    if (currentCameraPosition != AVCaptureDevicePositionBack)
    {
        isUsingFrontFacingCamera = TRUE;
    }
    
	switch (curDeviceOrientation) {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    
	imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];

    NSLog(@"Face Detector %@", [self.faceDetector description]);
    NSLog(@"converted Image %@", [convertedImage description]);
    NSArray *features = [self.faceDetector featuresInImage:convertedImage options:imageOptions];
    
    
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
    

    [self GPUVCWillOutputFeatures:features forClap:clap andOrientation:curDeviceOrientation];
    faceThinking = FALSE;
    
}

- (void)GPUVCWillOutputFeatures:(NSArray*)featureArray forClap:(CGRect)clap
                 andOrientation:(UIDeviceOrientation)curDeviceOrientation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Did receive array");
    
        CGRect previewBox = self.view.frame;
	
        if (featureArray == nil && faceView) {
            [faceView removeFromSuperview];
            faceView = nil;
        }
        
    
        for ( CIFaceFeature *faceFeature in featureArray) {
            
            // find the correct position for the square layer within the previewLayer
            // the feature box originates in the bottom left of the video frame.
            // (Bottom right if mirroring is turned on)
            NSLog(@"%@", NSStringFromCGRect([faceFeature bounds]));
            
            //Update face bounds for iOS Coordinate System
            CGRect faceRect = [faceFeature bounds];
            
            // flip preview width and height
            CGFloat temp = faceRect.size.width;
            faceRect.size.width = faceRect.size.height;
            faceRect.size.height = temp;
            temp = faceRect.origin.x;
            faceRect.origin.x = faceRect.origin.y;
            faceRect.origin.y = temp;
            // scale coordinates so they fit in the preview box, which may be scaled
            CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
            CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
            faceRect.size.width *= widthScaleBy;
            faceRect.size.height *= heightScaleBy;
            faceRect.origin.x *= widthScaleBy;
            faceRect.origin.y *= heightScaleBy;
            
            faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
            
            if (faceView) {
                [faceView removeFromSuperview];
                faceView =  nil;
            }
            
            // create a UIView using the bounds of the face
            faceView = [[UIView alloc] initWithFrame:faceRect];
            
            // add a border around the newly created UIView
            faceView.layer.borderWidth = 1;
            faceView.layer.borderColor = [[UIColor redColor] CGColor];
            
            // add the new view to create a box around the face
            [self.view addSubview:faceView];
            
        }
    });
    
}

-(IBAction)facesSwitched:(UISwitch*)sender{
    if (![sender isOn]) {
        [videoCamera setDelegate:nil];
        if (faceView) {
            [faceView removeFromSuperview];
            faceView = nil;
        }
    }else{
        [videoCamera setDelegate:self];

    }
}

#pragma mark -
#pragma mark Accessors

@synthesize filterSettingsSlider = _filterSettingsSlider;

@end

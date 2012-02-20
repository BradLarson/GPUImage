#import "ShowcaseFilterViewController.h"

@implementation ShowcaseFilterViewController

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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    GPUImageRotationFilter *rotationFilter = [[GPUImageRotationFilter alloc] initWithRotation:kGPUImageRotateRight];

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
            
            filter = [[GPUImagePixellateFilter alloc] init]; break;
        }; break;
        case GPUIMAGE_COLORINVERT:
        {
            self.title = @"Color Invert";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageColorInvertFilter alloc] init]; break;
        }; break;
        case GPUIMAGE_SATURATION:
        {
            self.title = @"Saturation";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            
            filter = [[GPUImageSaturationFilter alloc] init]; break;
        }; break;
        case GPUIMAGE_CONTRAST:
        {
            self.title = @"Contrast";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageContrastFilter alloc] init]; break;
        }; break;
        case GPUIMAGE_BRIGHTNESS:
        {
            self.title = @"Brightness";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.0];
            
            filter = [[GPUImageBrightnessFilter alloc] init]; break;
        }; break;
        case GPUIMAGE_GAMMA:
        {
            self.title = @"Gamma";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:3.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageGammaFilter alloc] init]; break;
        }; break;
        case GPUIMAGE_SOBELEDGEDETECTION:
        {
            self.title = @"Edge Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:1.0];
            
            filter = [[GPUImageSobelEdgeDetectionFilter alloc] init]; break;
        }; break;
        case GPUIMAGE_MULTIPLY:
        {
            self.title = @"Multiply Blend";
            self.filterSettingsSlider.hidden = YES;
            
            filter = [[GPUImageMultiplyBlendFilter alloc] init]; break;
        }; break;
        case GPUIMAGE_DISSOLVE:
        {
            self.title = @"Dissolve Blend";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
            filter = [[GPUImageDissolveBlendFilter alloc] init]; break;
        }; break;
        case GPUIMAGE_CUSTOM:
        {
            self.title = @"Custom";
            self.filterSettingsSlider.hidden = YES;

            filter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"CustomFilter"]; break;
        }; break;
        case GPUIMAGE_KUWAHARA:
        {
            self.title = @"Kuwahara";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:3.0];
            [self.filterSettingsSlider setMaximumValue:8.0];
            [self.filterSettingsSlider setValue:4.0];
            
            filter = [[GPUImageKuwaharaFilter alloc] init]; break;
        }; break;

        default: filter = [[GPUImageSepiaFilter alloc] init]; break;
    }
    
    [videoCamera addTarget:rotationFilter];
    [rotationFilter addTarget:filter];
    
    // The picture is only used for two-image blend filters
    UIImage *inputImage = [UIImage imageNamed:@"WID-small.jpg"];
    sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage];
    [sourcePicture addTarget:filter];

    GPUImageView *filterView = (GPUImageView *)self.view;
    [filter addTarget:filterView];
    
    [videoCamera startCameraCapture];
}

#pragma mark -
#pragma mark Filter adjustments

- (IBAction)updateFilterFromSlider:(id)sender;
{
    switch(filterType)
    {
        case GPUIMAGE_SEPIA: [(GPUImageSepiaFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PIXELLATE: [(GPUImagePixellateFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SATURATION: [(GPUImageSaturationFilter *)filter setSaturation:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CONTRAST: [(GPUImageContrastFilter *)filter setContrast:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BRIGHTNESS: [(GPUImageBrightnessFilter *)filter setBrightness:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GAMMA: [(GPUImageGammaFilter *)filter setGamma:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SOBELEDGEDETECTION: [(GPUImageSobelEdgeDetectionFilter *)filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_DISSOLVE: [(GPUImageDissolveBlendFilter *)filter setMix:[(UISlider *)sender value]]; break;
        case GPUIMAGE_KUWAHARA: [(GPUImageKuwaharaFilter *)filter setRadius:round([(UISlider *)sender value])]; break;
        default: break;
    }
}

#pragma mark -
#pragma mark Accessors

@synthesize filterSettingsSlider = _filterSettingsSlider;

@end

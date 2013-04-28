#import "SLSMultiViewWindowController.h"

@interface SLSMultiViewWindowController ()

@end

@implementation SLSMultiViewWindowController

@synthesize upperLeftView = _upperLeftView, upperRightView = _upperRightView, lowerLeftView = _lowerLeftView, lowerRightView = _lowerRightView;

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
    
    videoCamera = [[GPUImageAVCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionUnspecified];
    
    filter1 = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Shader1"];
    filter2 = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"Shader2"];
    filter3 = [[GPUImageSepiaFilter alloc] init];
    [filter1 forceProcessingAtSizeRespectingAspectRatio:self.upperRightView.sizeInPixels];
    [filter2 forceProcessingAtSizeRespectingAspectRatio:self.lowerLeftView.sizeInPixels];
    [filter3 forceProcessingAtSizeRespectingAspectRatio:self.upperRightView.sizeInPixels];

    [videoCamera addTarget:self.upperLeftView];
    [videoCamera addTarget:filter1];
    [filter1 addTarget:self.upperRightView];
    [videoCamera addTarget:filter2];
    [filter2 addTarget:self.lowerLeftView];
    [videoCamera addTarget:filter3];
    [filter3 addTarget:self.lowerRightView];
    
    [videoCamera startCameraCapture];
}

@end

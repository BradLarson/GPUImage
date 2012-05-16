#import "SimpleImageViewController.h"

@implementation SimpleImageViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView
{    
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];	
	GPUImageView *primaryView = [[GPUImageView alloc] initWithFrame:mainScreenFrame];
	self.view = primaryView;
    
    [self setupDisplayFiltering];
    [self setupImageFilteringToDisk];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark Image filtering

- (void)setupDisplayFiltering;
{
    UIImage *inputImage = [UIImage imageNamed:@"WID-small.jpg"]; // The WID.jpg example is greater than 2048 pixels tall, so it fails on older devices
    
    sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
    sepiaFilter = [[GPUImageSepiaFilter alloc] init];
  
    
    GPUImageView *imageView = (GPUImageView *)self.view;
    [sepiaFilter forceProcessingAtSize:imageView.sizeInPixels]; // This is now needed to make the filter run at the smaller output size
    
    [sourcePicture addTarget:sepiaFilter];
    [sepiaFilter addTarget:imageView];

    [sourcePicture processImage];
}

- (void)setupImageFilteringToDisk;
{
    // Set up a manual image filtering chain
    UIImage *inputImage = [UIImage imageNamed:@"Lambeau.jpg"];

    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:inputImage];
    GPUImageSepiaFilter *stillImageFilter = [[GPUImageSepiaFilter alloc] init];
    GPUImageVignetteFilter *vignetteImageFilter = [[GPUImageVignetteFilter alloc] init];
    vignetteImageFilter.vignetteEnd = 0.6;
    vignetteImageFilter.vignetteStart = 0.4;
    
    // There's a problem with the Kuwahara filter where it doesn't finish rendering before the image is extracted from it.
    // It looks like it only gets through certain tiles before glReadPixels() is called. Odd.
//    GPUImageKuwaharaFilter *stillImageFilter = [[GPUImageKuwaharaFilter alloc] init];
//    stillImageFilter.radius = 9;
    
    [stillImageSource addTarget:stillImageFilter];
    [stillImageFilter addTarget:vignetteImageFilter];
    [vignetteImageFilter prepareForImageCapture];
    [stillImageSource processImage];
    
    UIImage *currentFilteredImage = [vignetteImageFilter imageFromCurrentlyProcessedOutput];
        
    // Do a simpler image filtering
    GPUImageSketchFilter *stillImageFilter2 = [[GPUImageSketchFilter alloc] init];
    UIImage *quickFilteredImage = [stillImageFilter2 imageByFilteringImage:inputImage];

    
    // Write images to disk, as proof
    NSData *dataForPNGFile = UIImagePNGRepresentation(currentFilteredImage);
    NSData *dataForPNGFile2 = UIImagePNGRepresentation(quickFilteredImage);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSError *error = nil;
    if (![dataForPNGFile writeToFile:[documentsDirectory stringByAppendingPathComponent:@"Lambeau-filtered1.png"] options:NSAtomicWrite error:&error])
    {
        return;
    }
    if (![dataForPNGFile2 writeToFile:[documentsDirectory stringByAppendingPathComponent:@"Lambeau-filtered2.png"] options:NSAtomicWrite error:&error])
    {
        return;
    }    
}

@end

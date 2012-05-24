#import "FeatureExtractionAppDelegate.h"

@implementation FeatureExtractionAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    UIImage *inputImage = [UIImage imageNamed:@"71yih.png"];    
    GPUImagePicture *blackAndWhiteBoxImage = [[GPUImagePicture alloc] initWithImage:inputImage];
    
    [self testHarrisCornerDetectorAgainstPicture:blackAndWhiteBoxImage];
    
    return YES;
}

- (void)testHarrisCornerDetectorAgainstPicture:(GPUImagePicture *)pictureInput;
{
    [pictureInput removeAllTargets];
    
    GPUImageHarrisCornerDetectionFilter *harrisCornerFilter = [[GPUImageHarrisCornerDetectionFilter alloc] init];
    [pictureInput addTarget:harrisCornerFilter];
    
    GPUImageCrosshairGenerator *crosshairGenerator = [[GPUImageCrosshairGenerator alloc] init];
    crosshairGenerator.crosshairWidth = 5.0;
    [crosshairGenerator forceProcessingAtSize:[pictureInput outputImageSize]];
    
    [harrisCornerFilter setCornersDetectedBlock:^(GLfloat* cornerArray, NSUInteger cornersDetected) {
        [crosshairGenerator renderCrosshairsFromArray:cornerArray count:cornersDetected];
    }];
    
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    [pictureInput addTarget:blendFilter];
    pictureInput.targetToIgnoreForUpdates = blendFilter;
    
    [crosshairGenerator addTarget:blendFilter];
        
    [blendFilter prepareForImageCapture];
    [pictureInput processImage];
    
    NSUInteger currentImageIndex = 0;
    for (UIImage *currentImage in harrisCornerFilter.intermediateImages)
    {
        [self saveImage:currentImage fileName:[NSString stringWithFormat:@"Harris-%d.png", currentImageIndex]];
        
        currentImageIndex++;
    }
    
    UIImage *crosshairResult = [blendFilter imageFromCurrentlyProcessedOutput];
    
    [self saveImage:crosshairResult fileName:@"Harris-Crosshairs.png"];
}

- (void)saveImage:(UIImage *)imageToSave fileName:(NSString *)imageName;
{
    NSData *dataForPNGFile = UIImagePNGRepresentation(imageToSave);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSError *error = nil;
    if (![dataForPNGFile writeToFile:[documentsDirectory stringByAppendingPathComponent:imageName] options:NSAtomicWrite error:&error])
    {
        return;
    }
}

@end

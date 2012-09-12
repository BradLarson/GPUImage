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
    
    [self testHarrisCornerDetectorAgainstPicture:blackAndWhiteBoxImage withName:@"WhiteBoxes"];

    [self testNobleCornerDetectorAgainstPicture:blackAndWhiteBoxImage withName:@"WhiteBoxes"];
    [self testShiTomasiCornerDetectorAgainstPicture:blackAndWhiteBoxImage withName:@"WhiteBoxes"];
    
    // Testing erosion and dilation
    GPUImageErosionFilter *erosionFilter = [[GPUImageErosionFilter alloc] initWithRadius:4];
    [blackAndWhiteBoxImage removeAllTargets];
    [blackAndWhiteBoxImage addTarget:erosionFilter];
    [blackAndWhiteBoxImage processImage];
    UIImage *erosionImage = [erosionFilter imageFromCurrentlyProcessedOutput];
    [self saveImage:erosionImage fileName:@"Erosion4.png"];
    
    GPUImageDilationFilter *dilationFilter = [[GPUImageDilationFilter alloc] initWithRadius:4];
    [blackAndWhiteBoxImage removeAllTargets];
    [blackAndWhiteBoxImage addTarget:dilationFilter];
    [blackAndWhiteBoxImage processImage];
    UIImage *dilationImage = [dilationFilter imageFromCurrentlyProcessedOutput];
    [self saveImage:dilationImage fileName:@"Dilation4.png"];

    GPUImageOpeningFilter *openingFilter = [[GPUImageOpeningFilter alloc] initWithRadius:4];
    [blackAndWhiteBoxImage removeAllTargets];
    [blackAndWhiteBoxImage addTarget:openingFilter];
    [blackAndWhiteBoxImage processImage];
    UIImage *openingImage = [openingFilter imageFromCurrentlyProcessedOutput];
    [self saveImage:openingImage fileName:@"Opening4.png"];

    GPUImageClosingFilter *closingFilter = [[GPUImageClosingFilter alloc] initWithRadius:4];
    [blackAndWhiteBoxImage removeAllTargets];
    [blackAndWhiteBoxImage addTarget:closingFilter];
    [blackAndWhiteBoxImage processImage];
    UIImage *closingImage = [closingFilter imageFromCurrentlyProcessedOutput];
    [self saveImage:closingImage fileName:@"Closing4.png"];
    
    UIImage *compressionInputImage = [UIImage imageNamed:@"8pixeltest.png"];    
    GPUImagePicture *compressionImage = [[GPUImagePicture alloc] initWithImage:compressionInputImage];
    GPUImageColorPackingFilter *packingFilter = [[GPUImageColorPackingFilter alloc] init];
    [compressionImage addTarget:packingFilter];
    [compressionImage processImage];
    UIImage *compressedImage = [packingFilter imageFromCurrentlyProcessedOutput];
    [self saveImage:compressedImage fileName:@"Compression.png"];

    // Testing local binary patterns
    UIImage *inputLBPImage = [UIImage imageNamed:@"LBPTest.png"];
    GPUImagePicture *lbpImage = [[GPUImagePicture alloc] initWithImage:inputLBPImage];

    GPUImageLocalBinaryPatternFilter *lbpFilter = [[GPUImageLocalBinaryPatternFilter alloc] init];
    [lbpImage removeAllTargets];
    [lbpImage addTarget:lbpFilter];
    [lbpImage processImage];
    UIImage *lbpOutput = [lbpFilter imageFromCurrentlyProcessedOutput];
    [self saveImage:lbpOutput fileName:@"LocalBinaryPatterns.png"];

    // Testing image color averaging
    UIImage *chairImage = [UIImage imageNamed:@"ChairTest.png"];
    GPUImagePicture *chairPicture = [[GPUImagePicture alloc] initWithImage:chairImage];

    GPUImageAverageColor *averageColor = [[GPUImageAverageColor alloc] init];
    [averageColor setColorAverageProcessingFinishedBlock:^(CGFloat redComponent, CGFloat greenComponent, CGFloat blueComponent, CGFloat alphaComponent, CMTime frameTime){
        NSLog(@"Red: %f, green: %f, blue: %f, alpha: %f", redComponent, greenComponent, blueComponent, alphaComponent);
    }];
    
    GPUImageLuminosity *averageLuminosity = [[GPUImageLuminosity alloc] init];
    [averageLuminosity setLuminosityProcessingFinishedBlock:^(CGFloat luminosity, CMTime frameTime) {
        NSLog(@"Luminosity: %f", luminosity);
    }];
    
    [chairPicture removeAllTargets];
    [chairPicture addTarget:averageColor];
    [chairPicture addTarget:averageLuminosity];
    [chairPicture processImage];
//    UIImage *lbpOutput = [lbpFilter imageFromCurrentlyProcessedOutput];
//    [self saveImage:lbpOutput fileName:@"LocalBinaryPatterns.png"];
    
    return YES;
}

- (void)testCornerDetector:(GPUImageHarrisCornerDetectionFilter *)cornerDetector ofName:(NSString *)detectorName againstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
{
    cornerDetector.threshold = 0.4;
    cornerDetector.sensitivity = 4.0;
    cornerDetector.blurSize = 1.0;
    [pictureInput removeAllTargets];
    
    [pictureInput addTarget:cornerDetector];
    
    GPUImageCrosshairGenerator *crosshairGenerator = [[GPUImageCrosshairGenerator alloc] init];
    crosshairGenerator.crosshairWidth = 10.0;
    [crosshairGenerator setCrosshairColorRed:1.0 green:0.0 blue:0.0];
    [crosshairGenerator forceProcessingAtSize:[pictureInput outputImageSize]];
    
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    [blendFilter forceProcessingAtSize:[pictureInput outputImageSize]];
    [pictureInput addTarget:blendFilter];
    pictureInput.targetToIgnoreForUpdates = blendFilter;
    
    [crosshairGenerator addTarget:blendFilter];
    
    [blendFilter prepareForImageCapture];
    
    [cornerDetector setCornersDetectedBlock:^(GLfloat* cornerArray, NSUInteger cornersDetected, CMTime frameTime) {
        NSLog(@"Number of corners: %d", cornersDetected);
        [crosshairGenerator renderCrosshairsFromArray:cornerArray count:cornersDetected frameTime:frameTime];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUInteger currentImageIndex = 0;
            for (UIImage *currentImage in cornerDetector.intermediateImages)
            {
                [self saveImage:currentImage fileName:[NSString stringWithFormat:@"%@-%@-%d.png", detectorName, pictureName, currentImageIndex]];
                
                currentImageIndex++;
            }
            
            NSLog(@"Save corner image");
            UIImage *crosshairResult = [blendFilter imageFromCurrentlyProcessedOutput];
            
            [self saveImage:crosshairResult fileName:[NSString stringWithFormat:@"%@-%@-Crosshairs.png", detectorName, pictureName]];
        });
    }];
    

    [pictureInput processImage];
}

- (void)testHarrisCornerDetectorAgainstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
{
    GPUImageHarrisCornerDetectionFilter *harrisCornerFilter = [[GPUImageHarrisCornerDetectionFilter alloc] init];
    [self testCornerDetector:harrisCornerFilter ofName:@"Harris" againstPicture:pictureInput withName:pictureName];
}

- (void)testNobleCornerDetectorAgainstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
{
    GPUImageNobleCornerDetectionFilter *nobleCornerFilter = [[GPUImageNobleCornerDetectionFilter alloc] init];
    [self testCornerDetector:nobleCornerFilter ofName:@"Noble" againstPicture:pictureInput withName:pictureName];
}

- (void)testShiTomasiCornerDetectorAgainstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
{
    GPUImageShiTomasiFeatureDetectionFilter *nobleCornerFilter = [[GPUImageShiTomasiFeatureDetectionFilter alloc] init];
    [self testCornerDetector:nobleCornerFilter ofName:@"ShiTomasi" againstPicture:pictureInput withName:pictureName];
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

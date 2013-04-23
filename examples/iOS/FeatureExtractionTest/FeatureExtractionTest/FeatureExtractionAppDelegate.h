#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface FeatureExtractionAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)testHoughTransform:(GPUImageHoughTransformLineDetector *)lineDetector ofName:(NSString *)detectorName againstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
- (void)testCornerDetector:(GPUImageHarrisCornerDetectionFilter *)cornerDetector ofName:(NSString *)detectorName againstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
- (void)testHarrisCornerDetectorAgainstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
- (void)testNobleCornerDetectorAgainstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
- (void)testShiTomasiCornerDetectorAgainstPicture:(GPUImagePicture *)pictureInput withName:(NSString *)pictureName;
- (void)saveImage:(UIImage *)imageToSave fileName:(NSString *)imageName;

@end

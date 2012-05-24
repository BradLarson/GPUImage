#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface FeatureExtractionAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)testHarrisCornerDetectorAgainstPicture:(GPUImagePicture *)pictureInput;
- (void)saveImage:(UIImage *)imageToSave fileName:(NSString *)imageName;

@end

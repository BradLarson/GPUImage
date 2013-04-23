#import <UIKit/UIKit.h>

@class ColorTrackingViewController;

@interface ColorTrackingAppDelegate : UIResponder <UIApplicationDelegate>
{
    ColorTrackingViewController *colorTrackingViewController;
}

@property (strong, nonatomic) UIWindow *window;

@end

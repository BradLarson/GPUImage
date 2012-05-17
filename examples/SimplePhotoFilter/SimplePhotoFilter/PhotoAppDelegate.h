#import <UIKit/UIKit.h>

@class PhotoViewController;

@interface PhotoAppDelegate : UIResponder <UIApplicationDelegate>
{
    PhotoViewController *rootViewController;
}

@property (strong, nonatomic) UIWindow *window;

@end

#import <UIKit/UIKit.h>
@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    ViewController *rootViewController;
}

@property (strong, nonatomic) UIWindow *window;

@end

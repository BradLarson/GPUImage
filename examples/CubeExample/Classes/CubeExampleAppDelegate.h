#import <UIKit/UIKit.h>

@class DisplayViewController;

@interface CubeExampleAppDelegate : NSObject <UIApplicationDelegate> 
{
    DisplayViewController *rootViewController;

    UIWindow *window;
}

@property (strong, nonatomic) UIWindow *window;

@end


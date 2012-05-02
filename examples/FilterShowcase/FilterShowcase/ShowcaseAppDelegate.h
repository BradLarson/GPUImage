#import <UIKit/UIKit.h>

@class ShowcaseFilterListController;

@interface ShowcaseAppDelegate : UIResponder <UIApplicationDelegate>
{
    UINavigationController *filterNavigationController;

    ShowcaseFilterListController *filterListController;
}

@property (strong, nonatomic) UIWindow *window;

@end

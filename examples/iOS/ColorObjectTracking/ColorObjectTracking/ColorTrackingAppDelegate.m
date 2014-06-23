#import "ColorTrackingAppDelegate.h"
#import "ColorTrackingViewController.h"

@implementation ColorTrackingAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    colorTrackingViewController = [[ColorTrackingViewController alloc] initWithNibName:nil bundle:nil];
    [self.window addSubview:colorTrackingViewController.view];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Pause camera frame readings
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Reactivate camera frame readings
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end

#import "BenchmarkAppDelegate.h"
#import "ImageFilteringBenchmarkController.h"
#import "VideoFilteringBenchmarkController.h"

//  The tab bar icons in this application are courtesy of Joseph Wain / glyphish.com
//  See the GlyphishIconLicense.txt file for more information on these icons

@implementation BenchmarkAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    mainTabBarController = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
    
    imageFilteringBenchmarkController = [[ImageFilteringBenchmarkController alloc] initWithNibName:@"BenchmarkTableViewController" bundle:nil];
    UIImage *itemImage = [UIImage imageNamed:@"41-picture-frame"];
    UITabBarItem *mathTabItem = [[UITabBarItem alloc] initWithTitle:@"Still images" image:itemImage tag:0];
    imageFilteringBenchmarkController.tabBarItem = mathTabItem;

    
    videoFilteringBenchmarkController = [[VideoFilteringBenchmarkController alloc] initWithNibName:@"BenchmarkTableViewController" bundle:nil];
    UIImage *itemImage2 = [UIImage imageNamed:@"86-camera"];
    UITabBarItem *mathTabItem2 = [[UITabBarItem alloc] initWithTitle:@"Live video" image:itemImage2 tag:1];
    videoFilteringBenchmarkController.tabBarItem = mathTabItem2;
    
    NSArray *arrayOfViewControllers = [[NSArray alloc] initWithObjects:imageFilteringBenchmarkController, videoFilteringBenchmarkController, nil];
    
    mainTabBarController.viewControllers = arrayOfViewControllers;
    mainTabBarController.selectedViewController = imageFilteringBenchmarkController;
    
    [self.window addSubview:mainTabBarController.view];

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end

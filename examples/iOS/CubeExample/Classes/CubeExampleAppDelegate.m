#import "CubeExampleAppDelegate.h"
#import "DisplayViewController.h"

@implementation CubeExampleAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    rootViewController = [[DisplayViewController alloc] initWithNibName:nil bundle:nil];
    [self.window addSubview:rootViewController.view];
    self.window.rootViewController = rootViewController;

    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

- (void)dealloc
{
    [window release];

    [super dealloc];
}

@end

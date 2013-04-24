#import "SLSAppDelegate.h"

@implementation SLSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    windowController = [[SLSFilterShowcaseWindowController alloc] initWithWindowNibName:@"SLSFilterShowcaseWindowController"];
    [windowController showWindow:self];
}

@end

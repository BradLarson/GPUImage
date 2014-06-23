#import "SLSAppDelegate.h"

@implementation SLSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    multiViewWindowController = [[SLSMultiViewWindowController alloc] initWithWindowNibName:@"SLSMultiViewWindowController"];
    [multiViewWindowController showWindow:self];
}

@end

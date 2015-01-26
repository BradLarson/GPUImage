#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    windowController = [[ShaderDesignerWindowController alloc] initWithWindowNibName:@"ShaderDesignerWindowController"];
    [windowController showWindow:self];
}

@end

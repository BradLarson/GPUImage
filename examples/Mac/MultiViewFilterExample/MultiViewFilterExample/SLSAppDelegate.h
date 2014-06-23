#import <Cocoa/Cocoa.h>
#import "SLSMultiViewWindowController.h"

@interface SLSAppDelegate : NSObject <NSApplicationDelegate>
{
    SLSMultiViewWindowController *multiViewWindowController;
}

@property (assign) IBOutlet NSWindow *window;

@end

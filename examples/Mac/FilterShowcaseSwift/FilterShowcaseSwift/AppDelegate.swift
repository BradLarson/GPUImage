import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    var windowController:FilterShowcaseWindowController?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.windowController = FilterShowcaseWindowController(windowNibName:"FilterShowcaseWindowController")
        self.windowController?.showWindow(self)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
    }
}
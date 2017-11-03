import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let w = NSApp.mainWindow
        w?.isOpaque = false
        w?.backgroundColor = .clear
        w?.hasShadow = false
    }
}

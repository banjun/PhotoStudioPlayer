import Cocoa

let appDelegate = NSApp.delegate as! AppDelegate

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static let AppGlobalStateDidChange = NSNotification.Name(rawValue: "AppGlobalStateDidChange")

    @objc var enabledCaptureFrame = false {
        didSet {
            NotificationCenter.default.post(name: AppDelegate.AppGlobalStateDidChange, object: self)
        }
    }

    @objc var viewerAboveOtherApps = false {
        didSet {
            NotificationCenter.default.post(name: AppDelegate.AppGlobalStateDidChange, object: self)
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }
}

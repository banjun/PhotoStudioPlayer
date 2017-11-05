import AVFoundation
import AVKit
import Cocoa
import CoreImage
import CoreMediaIO

let appDelegate = NSApp.delegate as! AppDelegate

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
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
        var prop = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster))
        var allow: UInt32 = 1;
        CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop,
                                  0, nil,
                                  UInt32(MemoryLayout.size(ofValue: allow)), &allow)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let devices = availableDevices()
        if devices.isEmpty {
            menu.addItem(NSMenuItem(title: "<None>", action: nil, keyEquivalent: ""))
        } else {
            for device in devices {
                let menuItem = NSMenuItem(title: device.localizedName, action: #selector(openWindow(_:)), keyEquivalent: "")
                menuItem.representedObject = device.uniqueID
                menu.addItem(menuItem)
            }
        }
    }

    @objc private func openWindow(_ sender: NSMenuItem) {
    }

    private func availableDevices() -> [AVCaptureDevice] {
        return AVCaptureDevice.devices().filter {$0.hasMediaType(.muxed)}
    }
}

import AVFoundation
import AVKit
import Cocoa
import CoreImage
import CoreMediaIO

let appDelegate = NSApp.delegate as! AppDelegate

#if DEBUG
import SwiftHotReload
extension AppDelegate {
    static let reloader = StandaloneReloader(monitoredSwiftFile: URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("RuntimeOverrides.swift"))
}
#endif

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    static let AppGlobalStateDidChange = NSNotification.Name(rawValue: "AppGlobalStateDidChange")

    private var windowControllers = [NSWindowController]()
    private let windowDelegate = BorderlessWindowDelegate()

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

        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: nil) { n in
            guard let w = n.object as? NSWindow else { return }
            self.windowControllers = self.windowControllers.filter {$0.window != w}
        }
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
        guard let uniqueID = sender.representedObject as? String,
            let device = (availableDevices().first {$0.uniqueID == uniqueID}) else { return }

        guard let windowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "Window") as? NSWindowController else {
            return
        }
        windowController.window?.delegate = windowDelegate
        self.windowControllers.append(windowController)

        guard let vc = windowController.contentViewController as? ViewController else {
            return
        }
        vc.setDevice(device)
        windowController.showWindow(nil)
    }

    private func availableDevices() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.externalUnknown], mediaType: .muxed, position: .unspecified).devices
    }
}

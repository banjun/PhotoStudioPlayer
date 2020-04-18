//
//  BorderlessWindowDelegate.swift
//  PhotoStudioPlayer
//
//  Created by mzp on 2017/12/20.
//  Copyright © 2017 banjun. All rights reserved.
//
import Cocoa

class BorderlessWindowDelegate: NSObject, NSWindowDelegate {
    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            return
        }
        window.styleMask = [.titled, .fullSizeContentView, .closable, .miniaturizable, .resizable]
    }
    func windowDidResignKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            return
        }
        if #available(macOS 10.13, *) {
            window.styleMask = [.titled, .fullSizeContentView, .borderless]
        } else {
            window.styleMask = [.fullSizeContentView, .borderless]
        }
    }
}

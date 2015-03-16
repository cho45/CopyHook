//
//  PasteboardObserver.swift
//  CopyHook
//
//  Created by Satoh on 2015/03/16.
//  Copyright (c) 2015年 Satoh. All rights reserved.
//

import Cocoa

protocol PasteboardObserver {
    func observe(callback: ()->Void)
    func unobserve()
}

class KeyEventObserver: NSObject, PasteboardObserver {
    var callback : ()->Void = { () in }
    var monitor: AnyObject! = nil
    
    func observe(callback: ()->Void) {
        self.callback = callback
        
        if monitor != nil {
            unobserve()
        }
        monitor = NSEvent.addGlobalMonitorForEventsMatchingMask(NSEventMask.KeyDownMask) { (e: NSEvent!) in
            let cmd = (e.modifierFlags & NSEventModifierFlags.DeviceIndependentModifierFlagsMask).rawValue == NSEventModifierFlags.CommandKeyMask.rawValue
            
            if !cmd {
                return
            }
            
            if let key = e.charactersIgnoringModifiers?.uppercaseString {
                if key == "C" {
                    NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "treatCopy", userInfo: nil, repeats: false)
                }
            }
            
        }
    }
    
    func unobserve() {
        NSEvent.removeMonitor(monitor)
    }
    
    func treatCopy() {
        callback()
    }
}

class ChangeCountObserver: NSObject, PasteboardObserver {
    let pb = NSPasteboard.generalPasteboard()
    
    var callback : ()->Void = { () in }
    var changeCount : Int = 0
    var timer: NSTimer! = nil
    var pollingInterval: Double = 1.0
    
    init(pollingInterval: Double) {
        self.pollingInterval = pollingInterval
    }
    
    func observe(callback: ()->Void) {
        self.callback = callback
        if timer != nil {
            unobserve()
        }
        changeCount = pb.changeCount
        timer = NSTimer.scheduledTimerWithTimeInterval(pollingInterval, target: self, selector: "pollPasteboard", userInfo: nil, repeats: true)
    }
    
    func unobserve() {
        timer.invalidate()
        timer = nil
    }
    
    func pollPasteboard() {
        let pbChangeCount = pb.changeCount
        if pbChangeCount != changeCount {
            changeCount = pbChangeCount
            callback()
        }
    }
}
    

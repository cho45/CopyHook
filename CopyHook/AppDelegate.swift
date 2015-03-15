//
//  AppDelegate.swift
//  CopyHook
//
//  Created by Satoh on 2015/03/10.
//  Copyright (c) 2015年 Satoh. All rights reserved.
//

import Cocoa
import JavaScriptCore

protocol PasteboardObserver {
    init(callback: ()->Void)
    func observe()
    func unobserve()
}

class KeyEventObserver: NSObject, PasteboardObserver {
    var callback : ()->Void
    required init(callback: ()->Void) {
        self.callback = callback
    }
    
    var monitor: AnyObject!
    
    func observe() {
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
    var callback : ()->Void
    required init(callback: ()->Void) {
        self.callback = callback
    }
    
    let pb = NSPasteboard.generalPasteboard()
    var changeCount : Int = 0
    var timer: NSTimer!
    
    func observe() {
        if timer != nil {
            unobserve()
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "pollPasteboard", userInfo: nil, repeats: true)
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
    

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var menuEnabled: NSMenuItem!
    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var about: AboutWindow!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    
    var enabled: Bool = true {
        didSet {
            menuEnabled.state = enabled ? 1 : 0
        }
    }
    
    var lastLoadedTime: NSTimeInterval = 0
    
    var js : JSContext! = nil
    var bridge: CopyHookBridge! = nil
    
    let dotfile = NSHomeDirectory() + "/.copyhook.js"
    let dotdirectory = NSHomeDirectory() + "/.copyhook/"
    
    var observer: PasteboardObserver!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        Accessibility.checkAccessibilityEnabled(self)
        
        statusItem.menu = menu
        // statusItem.title = NSRunningApplication.currentApplication().localizedName!
        statusItem.image = NSImage(named: "menubar-icon")
        statusItem.highlightMode = true
        
        createJSContext()
        
        observer = ChangeCountObserver(callback: {() in
            self.treatCopy()
        })
        observer.observe()
    }
    
    func createJSContext() {
        js = JSContext()
        js.setObject(Pasteboard(context: js), forKeyedSubscript: "pasteboard")
        
        bridge = CopyHookBridge(context: js)
        js.setObject(bridge, forKeyedSubscript: "__bridge")
        
        bridge.setExceptionHandler()
        bridge.loadJavaScriptFile(NSBundle.mainBundle().pathForResource("init", ofType: "js")!)
        bridge.loadJavaScriptFile(dotfile)
    }
    
    func dotfilesTime()->NSTimeInterval {
        let fs = NSFileManager.defaultManager()
        var time: NSTimeInterval = 0
        
        // println("dotfilesTime")
        var files: [ String ] = [ dotfile ]
        let dir = fs.enumeratorAtPath(dotdirectory)
        while let file = dir?.nextObject() as? String {
            files.append(dotdirectory + file)
        }
        
        // println(files)
        
        for file in files {
            if let attrs: NSDictionary = fs.attributesOfItemAtPath(file.stringByResolvingSymlinksInPath, error: nil) {
                let date: NSDate = attrs.fileModificationDate()!
                if time < date.timeIntervalSince1970 {
                    time = date.timeIntervalSince1970
                }
            }
        }
        
        return time
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
    }
    
    func treatCopy() {
        if !enabled {
            return
        }
        
        let time: NSTimeInterval = dotfilesTime()
        if lastLoadedTime < time {
            println("reload")
            createJSContext()
            lastLoadedTime = time
        }
        
        /*
        let pb = NSPasteboard.generalPasteboard()
        println(pb.types)
        println(pb.stringForType("public.utf8-plain-text"))
        println(pb.stringForType("public.html"))
*/
        
        let cb : JSValue = js.objectForKeyedSubscript("onCopied")
        if !cb.isUndefined() {
            cb.callWithArguments([ ])
        } else {
            println("onCopied() is not defined.")
        }
    }
    
    @IBAction func toggleState(sender: AnyObject) {
        enabled = !enabled
    }
    
    @IBAction func showAbout(sender: AnyObject) {
        about.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps!(true)
    }
}


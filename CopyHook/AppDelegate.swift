//
//  AppDelegate.swift
//  CopyHook
//
//  Created by Satoh on 2015/03/10.
//  Copyright (c) 2015年 Satoh. All rights reserved.
//

import Cocoa
import JavaScriptCore

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var menuEnabled: NSMenuItem!
    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var window: NSWindow!
    
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
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        Accessibility.checkAccessibilityEnabled(self)
        
        statusItem.menu = menu
        statusItem.title = NSRunningApplication.currentApplication().localizedName!
        // statusItem.image = NSImage(named: "icon-menu")
        statusItem.highlightMode = true
        
        createJSContext()
        
        NSEvent.addGlobalMonitorForEventsMatchingMask(NSEventMask.KeyDownMask) { (e: NSEvent!) in
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
    
    func createJSContext() {
        js = JSContext()
        js.setObject(Pasteboard(), forKeyedSubscript: "pasteboard")
        
        bridge = CopyHookBridge(context: js)
        js.setObject(bridge, forKeyedSubscript: "__bridge")
        
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
}


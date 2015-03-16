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
    @IBOutlet weak var about: AboutWindow!
    @IBOutlet weak var preferences: PreferencesWindow!
    
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
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "userDefaultsDidChange:",
            name: NSUserDefaultsDidChangeNotification,
            object: nil
        )
        userDefaultsDidChange(nil)
    }
    
    func userDefaultsDidChange(aNotification: NSNotification!) {
        println("userDefaultsDidChange")
        
        if observer != nil {
            observer.unobserve()
        }
        switch preferences.monitoringMethod {
        case PreferencesWindow.MonitoringMethod.KeyEvent:
            observer = KeyEventObserver()
        case PreferencesWindow.MonitoringMethod.ChangeCount:
            observer = ChangeCountObserver(pollingInterval: preferences.pollingInterval)
        }
        println("Using \(_stdlib_getDemangledTypeName(observer!))")
        observer.observe(self.treatCopy)
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
        
        if preferences.autoReloading {
            let time: NSTimeInterval = dotfilesTime()
            if lastLoadedTime < time {
                println("reload")
                createJSContext()
                lastLoadedTime = time
            }
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
    
    @IBAction func openPreferencesWindow(sender: AnyObject) {
        preferences.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps!(true)
    }
}


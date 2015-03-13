//
//  AppDelegate.swift
//  CopyHook
//
//  Created by Satoh on 2015/03/10.
//  Copyright (c) 2015年 Satoh. All rights reserved.
//

import Cocoa
import JavaScriptCore

@objc protocol PasteboardJSExport : JSExport {
    func stringForType(type: String)->String?
    func clearContents()
    func setStringForType(str: String, _ type: String)
    func types()->[String]!
}

public class Pasteboard : NSObject, PasteboardJSExport {
    let pb = NSPasteboard.generalPasteboard()
    public func stringForType(type: String)->String? {
        return pb.stringForType(type)
    }
    
    public func clearContents() {
        pb.clearContents()
    }
    
    public func setStringForType(str: String, _ type: String) {
        pb.setString(str, forType: type)
    }
    
    public func types()->[String]! {
        if let types = pb.types {
            return types as [String]
        } else {
            return []
        }
    }
}

@objc protocol CopyHookBridgeJSExport : JSExport {
    func focusedApplicationBundleId()->String?
    func require(path: String)->Bool
    func log(str: String)
}

public class CopyHookBridge : NSObject, CopyHookBridgeJSExport {
    let context : JSContext
    init(context: JSContext) {
        self.context = context
    }
    
    public func log(str:String) {
        print(str)
    }
    
    public func focusedApplicationBundleId()->String? {
        var ptr: Unmanaged<AnyObject>?
        
        let system = AXUIElementCreateSystemWide().takeRetainedValue()
        
        AXUIElementCopyAttributeValue(system, "AXFocusedApplication", &ptr)
        if ptr == nil {
            return nil
        }
        let focusedApp = ptr!.takeRetainedValue() as AXUIElement
        
        var pid: pid_t = 0
        AXUIElementGetPid(focusedApp, &pid)
        
        return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
    }
    
    func require(path: String)->Bool {
        let file = NSHomeDirectory() + "/.copyhook/" + path
        return loadJavaScriptFile(file)
    }
    
    func loadJavaScriptFile(path: String)->Bool {
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            context.exceptionHandler = { (context: JSContext!, exception: JSValue!) -> Void in
                if exception.isObject() {
                    let line = exception.toDictionary()["line"] as NSNumber
                    let message = exception.toString()
                    println("\(path):\(line) \(message)")
                } else {
                    println("uncaught exception: \(exception)")
                }
            }
            
            let content = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
            context.evaluateScript(content)
            return true
        } else {
            return false
        }
    }
    
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var menuEnabled: NSMenuItem!
    @IBOutlet weak var menu: NSMenu!
    
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
                    NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "treatPasteboard", userInfo: nil, repeats: false)
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
        
        println(dotfile)
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
    
    func treatPasteboard() {
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
        
        if let cb = js.objectForKeyedSubscript("onCopied") {
            cb.callWithArguments([ ])
        } else {
            println("onCopied() is not defined.")
        }
    }
    
    @IBAction func toggleState(sender: AnyObject) {
        enabled = !enabled
    }
}


//
//  AppDelegate.swift
//  CopyHook
//
//  Created by Satoh on 2015/03/10.
//  Copyright (c) 2015年 Satoh. All rights reserved.
//

import Cocoa
import JavaScriptCore

@objc protocol PasteboardEventJSExport : JSExport {
    func stringForType(type: String)->String?
    func clearContents()
    func setStringForType(str: String, _ type: String)
    func focusedApplicationBundleId()->String?
}

public class PasteboardEvent : NSObject, PasteboardEventJSExport {
    public func stringForType(type: String)->String? {
        return NSPasteboard.generalPasteboard().stringForType(type)
    }
    
    public func clearContents() {
        NSPasteboard.generalPasteboard().clearContents()
    }
    
    public func setStringForType(str: String, _ type: String) {
        NSPasteboard.generalPasteboard().setString(str, forType: type)
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
}



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var js : JSContext! = nil
    
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let dotfile = NSHomeDirectory() + "/.copyhook.js"
        
        println(dotfile)
        
        let dotcontent = NSString(contentsOfFile: dotfile, encoding: NSUTF8StringEncoding, error: nil)!

        
        js = JSContext()
        js.exceptionHandler = { (context: JSContext!, exception: JSValue!) -> Void in
            println(exception)
        }
        
        js.setFunction( { (arg:AnyObject!) -> AnyObject in
            println(arg)
            return ""
        }, forKeyedSubscript: "log")
        
        js.evaluateScript(dotcontent)
        
        /*
        js.setObject("test", forKeyedSubscript: "test")
        
        
        let ret : JSValue = js.evaluateScript("test")
        let str = ret.toString()
        println(ret)
        
        println(js.evaluateScript("foo()"))
*/
        
        /*
        let rect = NSRect(x: 0, y: 0, width: 800, height: 500)
        let webview = WebView(frame: rect)
        println(webview)
        println(webview.stringByEvaluatingJavaScriptFromString("'foobar';"))
        */
        
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
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func treatPasteboard() {
        println("treatPasteboard")
        /*
        let pb = NSPasteboard.generalPasteboard()
        println(pb.types)
        println(pb.stringForType("public.utf8-plain-text"))
        println(pb.stringForType("public.html"))
*/
        
        let e = PasteboardEvent()
        if let cb = js.objectForKeyedSubscript("onCopied") {
            cb.callWithArguments([ e ])
        }
    }
    
}


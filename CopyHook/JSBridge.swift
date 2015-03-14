//
//  JSBridge.swift
//  CopyHook
//
//  Created by Satoh on 2015/03/14.
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
    func system(program: String, _ input: String)->String
    func focusedWindowName()->String?
}

public class CopyHookBridge : NSObject, CopyHookBridgeJSExport {
    let context : JSContext
    init(context: JSContext) {
        self.context = context
    }
    
    public func log(str:String) {
        NSLog(str)
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
    
    public func focusedWindowName()->String? {
        var ptr: Unmanaged<AnyObject>?
        
        let system = AXUIElementCreateSystemWide().takeRetainedValue()
        
        AXUIElementCopyAttributeValue(system, "AXFocusedApplication", &ptr)
        if ptr == nil {
            return nil
        }
        let focusedApp = ptr!.takeRetainedValue() as AXUIElement
        
        AXUIElementCopyAttributeValue(focusedApp, NSAccessibilityFocusedWindowAttribute, &ptr)
        if ptr == nil {
            return nil
        }
        let window = ptr!.takeRetainedValue() as AXUIElement
        AXUIElementCopyAttributeValue(window, NSAccessibilityTitleAttribute, &ptr)
        if ptr == nil {
            return nil
        }
        
        return ptr!.takeRetainedValue() as? String
    }
    
    func require(path: String)->Bool {
        let file = NSHomeDirectory() + "/.copyhook/" + path
        return loadJavaScriptFile(file)
    }
    
    func loadJavaScriptFile(path: String)->Bool {
        self.log("Load \(path)")
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            context.exceptionHandler = { (context: JSContext!, exception: JSValue!) -> Void in
                if exception.isObject() && !exception.isNull() {
                    let line : NSNumber = exception.toDictionary()["line"] as? NSNumber ?? 0
                    let message = exception.toString()
                    self.log("\(path):\(line) \(message)\n")
                } else {
                    self.log("uncaught exception: \(exception)\n")
                }
            }
            
            let content = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
            context.evaluateScript(content)
            return true
        } else {
            return false
        }
    }
    
    func system(program: String, _ input: String)->String {
        let pipeStdout = NSPipe()
        let stdout     = pipeStdout.fileHandleForReading
        let pipeStdin  = NSPipe()
        let stdin      = pipeStdin.fileHandleForWriting
        
        let task = NSTask()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", program]
        task.standardOutput = pipeStdout
        task.standardInput  = pipeStdin
        task.launch()
        stdin.writeData(input.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)
        stdin.closeFile()
        
        let ret = NSString(data: stdout.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)!
        return ret
    }
}


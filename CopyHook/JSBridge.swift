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
    func dataForType(type: String)->String?
    func dataForType2(type: String)->JSValue
    func setStringForType(str: String, _ type: String)->Bool
    func setDataForType(base64: String, _ type: String)->Bool
    func clearContents()
    func types()->[String]!
}

public class Pasteboard : NSObject, PasteboardJSExport {
    let pb = NSPasteboard.generalPasteboard()
    
    let context : JSContext
    init(context: JSContext) {
        self.context = context
    }
    
    public func stringForType(type: String)->String? {
        return pb.stringForType(type)
    }
    
    public func dataForType(type: String) -> String? {
        return pb.dataForType(type)?.base64EncodedStringWithOptions(nil)
    }
    
    public func dataForType2(type: String) -> JSValue {
        if let data = pb.dataForType(type) {
            let count = data.length / sizeof(UInt32)
            var bytes = [UInt32](count: count, repeatedValue: 0)
            data.getBytes(&bytes, length:count * sizeof(UInt32))

            let array = context.evaluateScript("new Uint32Array( \(count) )")
            for var i = 0; i < count; i++ {
                let byte = NSNumber(unsignedInt: bytes[i])
                array.setValue(byte, atIndex: i)
            }
            return array
        } else {
            return context.evaluateScript("null")
        }
    }
    
    public func setStringForType(str: String, _ type: String)->Bool {
        pb.setString(str, forType: type)
        return true
    }
    
    public func setDataForType(base64: String, _ type: String)->Bool {
        if let data = NSData(base64EncodedString: base64, options: nil) {
            pb.setData(data, forType: type)
            return true
        } else {
            return false
        }
    }
    
    public func clearContents() {
        pb.clearContents()
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
            let content = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
            if context.respondsToSelector("evaluateScript:withSourceURL:") {
                context.evaluateScript(content, withSourceURL: NSURL(fileURLWithPath: path))
            } else {
                // for 10.9 Mavericks
                context.evaluateScript(content)
            }
            return true
        } else {
            return false
        }
    }
    
    func setExceptionHandler() {
        context.exceptionHandler = { (context: JSContext!, exception: JSValue!) -> Void in
            if exception.isObject() && !exception.isNull() {
                let dict = exception.toDictionary()
                let url : String = dict["sourceURL"] as? String ?? ""
                let line : NSNumber = dict["line"] as? NSNumber ?? 0
                let column : NSNumber = dict["column"] as? NSNumber ?? 0
                let message = exception.toString()
                self.log("\(url):\(line):\(column) \(message)\n")
            } else {
                self.log("uncaught exception: \(exception)\n")
            }
        }
    }
    
    func system(program: String, _ input: String)->String {
        let pipeStdout = NSPipe()
        let stdout     = pipeStdout.fileHandleForReading
        let pipeStderr = NSPipe()
        let stderr     = pipeStderr.fileHandleForReading
        let pipeStdin  = NSPipe()
        let stdin      = pipeStdin.fileHandleForWriting
        
        let task = NSTask()
        task.currentDirectoryPath = NSHomeDirectory()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", program]
        task.standardOutput = pipeStdout
        task.standardInput  = pipeStdin
        task.standardError  = pipeStderr
        task.launch()
        stdin.writeData(input.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)
        stdin.closeFile()
        
        let ret = NSString(data: stdout.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)!
        let err = NSString(data: stderr.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)!
        log(err)
        return ret
    }
}


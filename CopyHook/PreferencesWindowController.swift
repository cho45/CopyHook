//
//  PreferencesWindowController.swift
//  CopyHook
//
//  Created by Satoh on 2015/03/16.
//  Copyright (c) 2015年 Satoh. All rights reserved.
//

import Cocoa

class PreferencesWindow: NSWindow {
    @IBOutlet weak var matrixMonitoringMethod: NSMatrix!
    
    let userDefaultsController = NSUserDefaultsController.sharedUserDefaultsController()
    
    enum MonitoringMethod : Int {
        case KeyEvent = 0, ChangeCount
    }
    
    var monitoringMethod : MonitoringMethod {
        get {
            let rawValue = userDefaultsController.values.valueForKey("monitoringMethod") as Int
            println(rawValue)
            return MonitoringMethod(rawValue: rawValue)!
        }
    }
    
    override func awakeFromNib() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.registerDefaults([
            "monitoringMethod": 0,
        ])
        defaults.synchronize()
        
        matrixMonitoringMethod.bind("selectedIndex", toObject: userDefaultsController, withKeyPath: "values.monitoringMethod", options: [ "NSContinuouslyUpdatesValue": true ])
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "userDefaultsDidChange:",
            name: NSUserDefaultsDidChangeNotification,
            object: nil
        )
        userDefaultsDidChange(nil)
    }
    
    func userDefaultsDidChange(aNotification: NSNotification!) {
    }
    
    override func cancelOperation(sender: AnyObject?) {
        close()
    }
    
}

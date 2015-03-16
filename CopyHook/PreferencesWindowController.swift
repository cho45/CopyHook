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
    @IBOutlet weak var textPollingInterval: NSTextField!
    @IBOutlet weak var checkAutoReloading: NSButton!
    
    let userDefaultsController = NSUserDefaultsController.sharedUserDefaultsController()
    
    enum MonitoringMethod : Int {
        case KeyEvent = 0, ChangeCount
    }
    
    var monitoringMethod : MonitoringMethod {
        get {
            let rawValue = userDefaultsController.values.valueForKey("monitoringMethod") as Int
            return MonitoringMethod(rawValue: rawValue)!
        }
    }
    
    var pollingInterval : Double {
        get {
            return userDefaultsController.values.valueForKey("pollingInterval") as Double
        }
    }
    
    var autoReloading: Bool {
        get {
            return userDefaultsController.values.valueForKey("autoReloading") as Bool
        }
    }

    override func awakeFromNib() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.registerDefaults([
            "monitoringMethod": 0,
            "pollingInterval": 1.0,
            "autoReloading": true,
        ])
        defaults.synchronize()
        
        matrixMonitoringMethod.bind("selectedIndex", toObject: userDefaultsController, withKeyPath: "values.monitoringMethod", options: [ "NSContinuouslyUpdatesValue": true ])
        textPollingInterval.bind("value", toObject: userDefaultsController, withKeyPath: "values.pollingInterval", options: [ "NSContinuouslyUpdatesValue": true ])
        checkAutoReloading.bind("value", toObject: userDefaultsController, withKeyPath: "values.autoReloading", options: [ "NSContinuouslyUpdatesValue": true ])
        
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "userDefaultsDidChange:",
            name: NSUserDefaultsDidChangeNotification,
            object: nil
        )
        userDefaultsDidChange(nil)
    }
    
    func userDefaultsDidChange(aNotification: NSNotification!) {
        switch monitoringMethod {
        case MonitoringMethod.KeyEvent:
            textPollingInterval.enabled = false
        case MonitoringMethod.ChangeCount:
            textPollingInterval.enabled = true
        }
    }
    
    override func cancelOperation(sender: AnyObject?) {
        close()
    }
    
}

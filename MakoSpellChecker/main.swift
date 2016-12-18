//
//  main.swift
//  MakoSpellChecker
//
//  Created by Makoto Yamashita on ’16.10.30.
//  Copyright © 2016 Makoto Yamashita. All rights reserved.
//

import Foundation

let aServer = NSSpellServer()
let myDelegate = MYSpellCheckerDelegate()
if (aServer.registerLanguage(myDelegate.langName, byVendor: "MakoSpellChecker")) {
    NSLog("MakoSpell Checker running.")
    aServer.delegate = myDelegate
    aServer.run()
    
    // We should not reach here
    NSLog("Unexpected death of MakoSpell Checker!")
} else {
    NSLog("Unable to check in MakoSpell Checker.")
}

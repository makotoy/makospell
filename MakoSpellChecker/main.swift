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
var didFail = false
for langCode in myDelegate.langCodes {
    let successRegisteringLang = aServer.registerLanguage(LanguageCodeHandler.convertLangCode(langCode), byVendor: "MakoSpellChecker")
    didFail = didFail || !successRegisteringLang
}
if (!didFail) {
    NSLog("MakoSpell Checker running with \(myDelegate.langCodes).")
    aServer.delegate = myDelegate
    aServer.run()
    
    // We should not reach here
    NSLog("Unexpected death of MakoSpell Checker!")
} else {
    NSLog("Unable to check in MakoSpell Checker.")
}

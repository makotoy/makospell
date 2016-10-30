//
//  main.swift
//  MYSpellChecker
//
//  Created by Makoto Yamashita on ’16.10.30.
//  Copyright © 2016 Makoto Yamashita. All rights reserved.
//

import Foundation

let aServer = NSSpellServer()

if (aServer.registerLanguage("English", byVendor: "MakoSpell")) {
    let myDelegate = MYSpellCheckerDelegate()
    NSLog("MakoSpell Checker running.")
    aServer.delegate = myDelegate
    aServer.run()
    print("Unexpected death of MakoSpell Checker!")
} else {
    print("Unable to check in MakoSpell Checker.")
}

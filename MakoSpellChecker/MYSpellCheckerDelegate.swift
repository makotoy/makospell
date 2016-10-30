//
//  MYSpellCheckerDelegate.swift
//  MYSpellChecker
//
//  Created by Makoto Yamashita on ’16.10.30.
//  Copyright © 2016 Makoto Yamashita. All rights reserved.
//

import Foundation

class MYSpellCheckerDelegate: NSObject, NSSpellServerDelegate {
//    func spellServer(_ sender: NSSpellServer,
//                     check stringToCheck: String,
//                     offset: Int,
//                     types checkingTypes: NSTextCheckingTypes,
//                     options: [String : Any]? = nil,
//                     orthography: NSOrthography?,
//                     wordCount: UnsafeMutablePointer<Int>) -> [NSTextCheckingResult]? {
//    return []
//    }
    func spellServer(_ sender: NSSpellServer,
                     suggestGuessesForWord word: String,
                     inLanguage language: String) -> [String]? {
        return ["bar"]
    }
//    func spellServer(_ sender: NSSpellServer,
//                     checkGrammarIn stringToCheck: String,
//                     language: String?,
//                     details: AutoreleasingUnsafeMutablePointer<NSArray?>?) -> NSRange {
//        return NSRange(location: 0, length: 0)
//    }
    func spellServer(_ sender: NSSpellServer,
                     findMisspelledWordIn stringToCheck: String,
                     language: String,
                     wordCount: UnsafeMutablePointer<Int>,
                     countOnly: Bool) -> NSRange {
        let fooLen = stringToCheck.index(stringToCheck.startIndex, offsetBy: 3)
        if (stringToCheck.substring(to: fooLen) == "foo") {
          return NSRange(location: 0, length: 3)
        } else {
            return NSRange(location: 0, length: 0)
        }
    }
    func spellServer(_ sender: NSSpellServer,
                     didForgetWord word: String,
                     inLanguage language: String) {
        
    }
    func spellServer(_ sender: NSSpellServer,
                     didLearnWord word: String,
                     inLanguage language: String) {
    }
    func spellServer(_ sender: NSSpellServer,
                     suggestCompletionsForPartialWordRange range: NSRange,
                     in string: String,
                     language: String) -> [String]? {
        return ["poo"]
    }
    func spellServer(_ sender: NSSpellServer,
                     recordResponse response: Int,
                     toCorrection correction: String,
                     forWord word: String,
                     language: String) {
        
    }
}

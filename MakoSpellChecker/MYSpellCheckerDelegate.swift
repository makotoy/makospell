//
//  MYSpellCheckerDelegate.swift
//  MakoSpellChecker
//
//  Created by Makoto Yamashita on ’16.10.30.
//  Copyright © 2016 Makoto Yamashita. All rights reserved.
//

import Foundation

class MYSpellCheckerDelegate: NSObject, NSSpellServerDelegate {
    var aSpellProcess : Process?
    var aSpellInputPipe : Pipe?
    var aSpellOutputPipe : Pipe?
    var spell_checker: OpaquePointer?
    
    override init() {
        
        aSpellProcess = Process()
        //setup aspell process
        aSpellProcess?.launchPath = "/usr/local/bin/aspell"
        aSpellProcess?.arguments = ["-a", "--conf=/Users/makotoy/.aspell.conf"]
        aSpellInputPipe = Pipe()
        aSpellOutputPipe = Pipe()
        aSpellProcess?.standardInput = aSpellInputPipe
        aSpellProcess?.standardOutput = aSpellOutputPipe
        // launch aspell process
        aSpellProcess?.launch()
        
        spell_checker = nil
        var spell_config = new_aspell_config()
        aspell_config_replace(spell_config, "lang", "en_US")
        aspell_config_replace(spell_config, "dict-dir", "/Library/Application Support/cocoAspell/aspell6-en-6.0-0")
        aspell_config_replace(spell_config, "home-dir", "/Users/makotoy/Library/Preferences/cocoAspell/")
        aspell_config_replace(spell_config, "personal", "en.pws")

        let possible_err = new_aspell_speller(spell_config)
        if (aspell_error_number(possible_err) != 0) {
            let error_msg = String.init(cString: aspell_error_message(possible_err))
            NSLog(error_msg)
        } else {
            spell_checker = to_aspell_speller(possible_err)
        }
        super.init()
    }
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
        return ["bar", "poo"]
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
        let strToCheckAsNSStr = stringToCheck as NSString
        let matchRan = strToCheckAsNSStr.range(of: "foo")
        return matchRan
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
        return ["boongaboonga"]
    }
    func spellServer(_ sender: NSSpellServer,
                     recordResponse response: Int,
                     toCorrection correction: String,
                     forWord word: String,
                     language: String) {
        
    }
}

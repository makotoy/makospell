//
//  MYSpellCheckerDelegate.swift
//  MakoSpellChecker
//
//  Created by Makoto Yamashita on ’16.10.30.
//  Copyright © 2016 Makoto Yamashita. All rights reserved.
//

import Foundation
import AppKit

class MYSpellCheckerDelegate: NSObject, NSSpellServerDelegate {
    var spell_checker: OpaquePointer? = nil
    var doc_checker: OpaquePointer? = nil
    var langName: String = "Unset"
    
    override init() {
        // prepare aspell config
        let spell_config = new_aspell_config()
        var aspell_conf_path = (NSHomeDirectory() as NSString).appendingPathComponent(".aspell.conf")
        let env_var_dic = ProcessInfo().environment
        if env_var_dic["MYSpellCheckerAspellConf"] != nil {
            aspell_conf_path = env_var_dic["MYSpellCheckerAspellConf"]!
        }
        let fileMan = FileManager()
        if fileMan.fileExists(atPath: aspell_conf_path) {
            propagateAspellConf(confPath: aspell_conf_path, confPtr: spell_config!)
        } else {
            NSLog("Could not find Aspell config file \(aspell_conf_path)")
        }
        // want input encoding to be UTF-8
        let encoding_name = String(cString:aspell_config_retrieve(spell_config, "encoding"))
        if encoding_name != "utf-8" {
            if encoding_name == "none" {
                aspell_config_replace(spell_config, "encoding", "utf-8")
            } else {
                NSLog("Aspell conf has encoding \(encoding_name), but Mac OS X spell system would give UTF-8 data (like non-breaking space 0xc2 0xa0)")
            }
        }
        // language name
        let lang_code = String(cString:aspell_config_retrieve(spell_config, "lang"))
        langName = LanguageCodeHandler.convertLangCode(lang_code)
        // instantiate spell checker
        let possible_err = new_aspell_speller(spell_config)
        if aspell_error_number(possible_err) != 0 {
            let error_msg = String(cString: aspell_error_message(possible_err))
            NSLog(error_msg)
        } else {
            spell_checker = to_aspell_speller(possible_err)
            // sync word list
            let sysListDir = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Library/Spelling")
            let sysListPath = sysListDir.appendingPathComponent(langName).path
            let aspellListDir = URL(fileURLWithPath: String(cString: aspell_config_retrieve(spell_config, "home-dir")))
            let aspellFileName = String(cString: aspell_config_retrieve(spell_config, "personal"))
            let aspellListPath = aspellListDir.appendingPathComponent(aspellFileName).path
            if fileMan.fileExists(atPath: sysListPath) && fileMan.fileExists(atPath: aspellListDir.path) {
                syncPersonalWordList(spell_checker, sysListPath: sysListPath, aspellListPath: aspellListPath)
            }
            // instantiate doc checker
            let possible_err_doc = new_aspell_document_checker(spell_checker)
            if (aspell_error_number(possible_err_doc) != 0) {
                let error_msg_doc = String(cString:aspell_error_message(possible_err_doc))
                NSLog(error_msg_doc)
            } else {
                doc_checker = to_aspell_document_checker(possible_err_doc)
            }
        }
        // clear aspell config
        delete_aspell_config(spell_config)
        // hand the task to superclass
        super.init()
    }
    
    deinit {
        delete_aspell_document_checker(doc_checker)
        delete_aspell_speller(spell_checker)
    }
    
    func spellServer(_ sender: NSSpellServer,
                     check stringToCheck: String,
                     offset: Int,
                     types checkingTypes: NSTextCheckingTypes,
                     options: [String : Any]? = nil,
                     orthography: NSOrthography?,
                     wordCount: UnsafeMutablePointer<Int>) -> [NSTextCheckingResult]? {
        guard doc_checker != nil else {
            return nil
        }
        guard (checkingTypes & NSTextCheckingResult.CheckingType.spelling.rawValue) != 0 else {
            NSLog("Was asked to perform something other than spell check; NSTextCheckingTypes \(checkingTypes)")
            return nil
        }
        let utf8Rep = stringToCheck.utf8CString
        utf8Rep.withUnsafeBufferPointer { ptr in
            aspell_document_checker_process(doc_checker, ptr.baseAddress!, -1)
        }
        var error_loc = aspell_document_checker_next_misspelling(doc_checker)
        if error_loc.len == 0 {
            wordCount.pointee = countWords(stringToCheck)
            return nil
        }
        let toFirstMisspell = String(stringToCheck.utf8.prefix(Int(error_loc.offset)))
        wordCount.pointee = countWords(toFirstMisspell)
        var spellRes = [NSTextCheckingResult]()
        repeat {
            guard let beforeThisMiss = String(stringToCheck.utf8.prefix(Int(error_loc.offset))) else {
                NSLog("Could not convert string portion before misstake, offset \(error_loc.offset) in utf8 \(hexDump(stringToCheck.utf8))")
                continue
            }
            let beforeThisMissLen = (beforeThisMiss as NSString).length
            let fromMissView: String.UTF8View = stringToCheck.utf8.dropFirst(Int(error_loc.offset))
            guard let thisMissWord = String(fromMissView.prefix(Int(error_loc.len))) else {
                NSLog("Could not convert missspell, offset \(error_loc.offset), len \(error_loc.len) in utf8 \(hexDump(stringToCheck.utf8))")
                    continue
            }
            let missLen = (thisMissWord as NSString).length
            let thisRange = NSRange(location: offset + beforeThisMissLen, length: missLen)
            spellRes.append(NSTextCheckingResult.spellCheckingResult(range: thisRange))
            error_loc = aspell_document_checker_next_misspelling(doc_checker)
        } while (error_loc.len != 0)
        return spellRes
    }
    func spellServer(_ sender: NSSpellServer,
                     suggestGuessesForWord word: String,
                     inLanguage language: String) -> [String]? {
        guard spell_checker != nil else {
            return nil
        }
        let suggestions = aspell_speller_suggest(spell_checker, word, -1)
        let elements = aspell_word_list_elements(suggestions)
        var nextWordPtr = aspell_string_enumeration_next(elements)
        var suggestedWords = [String]()
        while nextWordPtr != nil {
            suggestedWords.append(String(cString: nextWordPtr!))
            nextWordPtr = aspell_string_enumeration_next(elements)
        }
        delete_aspell_string_list(elements)
        return suggestedWords
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
        guard spell_checker != nil else {
            return NSRange(location: NSNotFound, length: 0)
        }
        if countOnly {
            wordCount.pointee = countWords(stringToCheck)
            return NSRange(location: NSNotFound, length: 0)
        }
        // split into words, ignore punctuations except backslash (tex)
        let nonalphas = CharacterSet(charactersIn: "A"..."z").inverted
        var wordBdry = CharacterSet.letters.inverted
        wordBdry.remove(charactersIn:"\\")
        let wordsArray = stringToCheck.components(separatedBy: wordBdry)
        for (_, wordToCheck) in wordsArray.enumerated() {
            // ignore tex macros
            if wordToCheck.hasPrefix("\\") {
                continue
            }
            // ignore unless alphabets
            if wordToCheck.rangeOfCharacter(from: nonalphas) != nil {
                continue
            }
            // return range of first unknown word
            if 0 == aspell_speller_check(spell_checker, wordToCheck, -1) {
                let strToCheckAsNSStr = stringToCheck as NSString
                let matchRan = strToCheckAsNSStr.range(of: wordToCheck)
                return matchRan
            }
        }
        // all words known
        return NSRange(location: NSNotFound, length: 0)
    }
//    func spellServer(_ sender: NSSpellServer,
//                     didForgetWord word: String,
//                     inLanguage language: String) {
//        
//    }
    func spellServer(_ sender: NSSpellServer,
                     didLearnWord word: String,
                     inLanguage language: String) {
        NSLog("learning \(word)")
        let utf8Rep = word.utf8CString
        _ = utf8Rep.withUnsafeBufferPointer { ptr in
            aspell_speller_add_to_session(spell_checker, ptr.baseAddress!, -1)
        }
    }
//    func spellServer(_ sender: NSSpellServer,
//                     suggestCompletionsForPartialWordRange range: NSRange,
//                     in string: String,
//                     language: String) -> [String]? {
//    }
    func spellServer(_ sender: NSSpellServer,
                     recordResponse response: Int,
                     toCorrection correction: String,
                     forWord word: String,
                     language: String) {
        // only called if accepts, rejects, edits
        NSLog("recordResponse called with code \(response) with correction \(correction) for word \(word)")
        switch response {
        case NSCorrectionResponse.accepted.rawValue:
            NSLog("accepted correction \(correction) for \(word)")
            let wordUtf8Rep = word.utf8CString
            let corrUtf8Rep = correction.utf8CString
            _ = wordUtf8Rep.withUnsafeBufferPointer { wrdPtr in
                corrUtf8Rep.withUnsafeBufferPointer{ corrPtr in
                    aspell_speller_store_replacement(spell_checker, wrdPtr.baseAddress!, -1, corrPtr.baseAddress!, -1)
                }
            }
        default: break
        }
    }
}

func countWords(_ string: String?) -> Int {
    if string == nil || string! == "" {
        return 0
    }
    let wordsArray = string!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
    return wordsArray.filter({str in (str != "")}).count
}

func hexDump<T: Sequence>(_ ui8seq: T) -> String where T.Iterator.Element == UInt8 {
    let resStrList = ui8seq.map { byte in
        String(format: "%02x", byte)
    }
    return resStrList.joined(separator: " ")
}

// cannot resolve above in unit test
func hexDump(_ ui8seq: String.UTF8View) -> String {
    let resStrList = ui8seq.map { byte in
        String(format: "%02x", byte)
    }
    return resStrList.joined(separator: " ")
}

func propagateAspellConf(confPath: String, confPtr: OpaquePointer) {
    guard let confStr = try? String(contentsOfFile: confPath, encoding: String.Encoding.utf8) else {
        NSLog("Could not read from aspell conf file \(confPath)")
        return
    }
    let confList = confStr.components(separatedBy: CharacterSet.newlines)
    for (_, line) in confList.enumerated() {
        guard let firstSpace = line.rangeOfCharacter(from: CharacterSet.whitespaces) else {
            continue
        }
        let keyStr = line.substring(to: firstSpace.lowerBound)
        let valStr = line.substring(from: firstSpace.upperBound)
        if (keyStr == "" || valStr == "") {
            continue
        }
        aspell_config_replace(confPtr, keyStr, valStr)
    }
}

@discardableResult
func syncPersonalWordList(_ spellChecker: OpaquePointer?, sysListPath: String, aspellListPath: String) -> Bool {
    let fileMan = FileManager()
    
    if !fileMan.fileExists(atPath: sysListPath) {
        NSLog("Asked to read from system word list path at \(sysListPath), but it does not exist")
        return false
    }
    guard let sysListStr = try? String(contentsOfFile: sysListPath, encoding: String.Encoding.utf8) else {
        NSLog("Could not read the contents of \(sysListPath)")
        return false
    }
    let sysList = sysListStr.components(separatedBy: CharacterSet.newlines)
    
    if !fileMan.fileExists(atPath: aspellListPath){
        NSLog("Asked to read from Aspell word list path at \(aspellListPath), but it does not exist")
        return false
    }
    guard let aspellListStr = try? String(contentsOfFile: aspellListPath, encoding: String.Encoding.utf8) else {
        NSLog("Could not read the contents of \(aspellListPath)")
        return false
    }
    let aspellList = aspellListStr.components(separatedBy: CharacterSet.newlines)
    
    var wordAdded = false
    for (_, word) in sysList.enumerated() {
        if !aspellList.contains(word) {
            let utf8Rep = word.utf8CString
            _ = utf8Rep.withUnsafeBufferPointer { ptr in
                aspell_speller_add_to_personal(spellChecker, ptr.baseAddress!, -1)
            }
            wordAdded = true
            NSLog("Adding word \(word) to personal list")
        }
    }
    if wordAdded {
        aspell_speller_save_all_word_lists(spellChecker)
    }
    
    return wordAdded
}

struct LanguageCodeHandler {
    static let codeDict = ["en": "English", "de": "German", "fr": "French"]
    
    static func convertLangCode(_ code: String) -> String {
        for (_, langCode) in codeDict.keys.enumerated() {
            if code.hasPrefix(langCode) {
                return codeDict[langCode]!
            }
        }
        NSLog("Unknown ISO 639 code \(code) was queried.")
        return "Unknown"
    }
}

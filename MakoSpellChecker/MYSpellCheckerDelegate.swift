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
    
    override init() {
        let spell_config = new_aspell_config()
        var aspell_conf_path = NSHomeDirectory() + "/.aspell.conf"
        let env_var_dic = ProcessInfo().environment
        if (env_var_dic["MYSpellCheckerAspellConf"] != nil) {
            aspell_conf_path = env_var_dic["MYSpellCheckerAspellConf"]!
        }
        let fileMan = FileManager()
        if (fileMan.fileExists(atPath: aspell_conf_path)) {
            aspell_config_replace(spell_config, "conf", aspell_conf_path)
        } else {
            NSLog("Could not find Aspell config file \(aspell_conf_path)")
        }

        let possible_err = new_aspell_speller(spell_config)
        if (aspell_error_number(possible_err) != 0) {
            let error_msg = String(cString: aspell_error_message(possible_err))
            NSLog(error_msg)
        } else {
            spell_checker = to_aspell_speller(possible_err)
            let possible_err_doc = new_aspell_document_checker(spell_checker)
            if (aspell_error_number(possible_err_doc) != 0) {
                let error_msg_doc = String(cString:aspell_error_message(possible_err_doc))
                NSLog(error_msg_doc)
            } else {
                doc_checker = to_aspell_document_checker(possible_err_doc)
            }
        }
        delete_aspell_config(spell_config)
        super.init()
    }
    
//    deinit {
//    }
    
    func spellServer(_ sender: NSSpellServer,
                     check stringToCheck: String,
                     offset: Int,
                     types checkingTypes: NSTextCheckingTypes,
                     options: [String : Any]? = nil,
                     orthography: NSOrthography?,
                     wordCount: UnsafeMutablePointer<Int>) -> [NSTextCheckingResult]? {
        if ((checkingTypes & NSTextCheckingResult.CheckingType.spelling.rawValue) == 0) {
            return nil
        }
        if (doc_checker == nil) {
            return nil
        }
        var utf8Rep = stringToCheck.utf8CString
        utf8Rep.withUnsafeBufferPointer { ptr in
            aspell_document_checker_process(doc_checker, ptr.baseAddress!, -1)
        }
        var error_loc = aspell_document_checker_next_misspelling(doc_checker)
        if (error_loc.len == 0) {
            wordCount.pointee = countWords(string: stringToCheck)
            return nil
        }
        if (error_loc.offset == 0) {
            wordCount.pointee = 0
        } else {
            utf8Rep.withUnsafeMutableBufferPointer { ptr in
                let cStrUntilOffsetData = Data(bytesNoCopy: ptr.baseAddress!, count: Int(error_loc.offset), deallocator: Data.Deallocator.none)
                let toFirstMisspell = String(data: cStrUntilOffsetData, encoding: String.Encoding.utf8)
                wordCount.pointee = countWords(string: toFirstMisspell)
            }
        }
        var spellRes = [NSTextCheckingResult]()
        repeat {
            utf8Rep.withUnsafeMutableBufferPointer { ptr in
                let cStrBeforeMissData = Data(bytesNoCopy: ptr.baseAddress!, count: Int(error_loc.offset), deallocator: Data.Deallocator.none)
                let beforeMiss = String(data: cStrBeforeMissData, encoding: String.Encoding.utf8)
                let beforeMissLen = (beforeMiss != nil) ? (beforeMiss! as NSString).length : 0
                let cStrMissData = Data(bytesNoCopy: ptr.baseAddress! + Int(error_loc.offset), count: Int(error_loc.len), deallocator: Data.Deallocator.none)
                let missWord = String(data: cStrMissData, encoding: String.Encoding.utf8)
                let thisRange = NSRange(location: offset + beforeMissLen, length: (missWord! as NSString).length)
                spellRes.append(NSTextCheckingResult.spellCheckingResult(range: thisRange))
            }
            error_loc = aspell_document_checker_next_misspelling(doc_checker)
        } while (error_loc.len != 0)
        return spellRes
    }
    func spellServer(_ sender: NSSpellServer,
                     suggestGuessesForWord word: String,
                     inLanguage language: String) -> [String]? {
        let suggestions = aspell_speller_suggest(spell_checker, word, -1)
        let elements = aspell_word_list_elements(suggestions)
        var nextWordPtr = aspell_string_enumeration_next(elements)
        if (nextWordPtr == nil) {
            return nil
        }
        var suggestedWords = [String]()
        repeat {
            suggestedWords.append(String(cString: nextWordPtr!))
            nextWordPtr = aspell_string_enumeration_next(elements)
        } while (nextWordPtr != nil)
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
        // split into words, ignore punctuations except backslash (tex)
        let nonalphas = CharacterSet(charactersIn: "A"..."z").inverted
        var wordBdry = CharacterSet.letters.inverted
        wordBdry.remove(charactersIn:"\\")
        let wordsArray = stringToCheck.components(separatedBy: wordBdry)
        for (_, wordToCheck) in wordsArray.enumerated() {
            // ignore tex macros
            if (wordToCheck.hasPrefix("\\")) {
                continue
            }
            // ignore unless alphabets
            let nonalpharan = wordToCheck.rangeOfCharacter(from: nonalphas)
            if (nonalpharan != nil) {
                continue
            }
            // return range of first unknown word
            if (0 == aspell_speller_check(spell_checker, wordToCheck, -1)) {
                let strToCheckAsNSStr = stringToCheck as NSString
                let matchRan = strToCheckAsNSStr.range(of: wordToCheck)
                return matchRan
            }
        }
        // all words known
        return NSRange(location: NSNotFound, length: 0)
    }
    func spellServer(_ sender: NSSpellServer,
                     didForgetWord word: String,
                     inLanguage language: String) {
        
    }
    func spellServer(_ sender: NSSpellServer,
                     didLearnWord word: String,
                     inLanguage language: String) {
        NSLog("learning \(word)")
        let utf8Rep = word.utf8CString
        utf8Rep.withUnsafeBufferPointer { ptr in
            aspell_speller_add_to_personal(spell_checker, ptr.baseAddress!, Int32(utf8Rep.count))
            aspell_speller_save_all_word_lists(spell_checker)
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
            wordUtf8Rep.withUnsafeBufferPointer { wrdPtr in
                corrUtf8Rep.withUnsafeBufferPointer{ corrPtr in
                    aspell_speller_store_replacement(spell_checker, wrdPtr.baseAddress!, Int32(wordUtf8Rep.count), corrPtr.baseAddress!, Int32(corrUtf8Rep.count))
                }
            }
            
        case NSCorrectionResponse.ignored.rawValue:
            NSLog("trying to ignore \(word)")
            let utf8Rep = word.utf8CString
            utf8Rep.withUnsafeBufferPointer { ptr in
                aspell_speller_add_to_session(spell_checker, ptr.baseAddress!, Int32(utf8Rep.count))
            }

        default: break
        }
    }
}

func countWords(string: String?) -> Int {
    if (string == nil || string! == "") {
        return 0
    }
    let wordsArray = string!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
    return wordsArray.filter({str in (str != "")}).count
}

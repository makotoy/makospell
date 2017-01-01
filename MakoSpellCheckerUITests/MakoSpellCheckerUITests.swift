//
//  MakoSpellCheckerUITests.swift
//  MakoSpellCheckerUITests
//
//  Created by Makoto Yamashita on ’16.10.30.
//  Copyright © 2016 Makoto Yamashita. All rights reserved.
//

import XCTest
@testable import MakoSpellChecker

class MakoSpellCheckerUITests: XCTestCase {
    var spellServer: NSSpellServer!
    var checkerDelegate: MYSpellCheckerDelegate!
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        spellServer = NSSpellServer()
        checkerDelegate = MYSpellCheckerDelegate()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
//        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTrue() {
        // dummy test which should always pass
        XCTAssert(true)
    }
    
    func testFooCheck() {
        var dummyCounter: Int = 0
        let resRange = checkerDelegate.spellServer(spellServer, findMisspelledWordIn: "beedybardy bar", language: "English", wordCount: &dummyCounter, countOnly: false)
        XCTAssert(NSEqualRanges(resRange, NSRange(location: 0, length: 10)))
    }
    
    func testPooCheck() {
        var dummyCounter: Int = 0
        let resRange = checkerDelegate.spellServer(spellServer, findMisspelledWordIn: "poo bar", language: "English", wordCount: &dummyCounter, countOnly: false)
        XCTAssert(resRange.location == NSNotFound)
    }
    
    func testTexIgnore() {
        var dummyCounter: Int = 0
        let resRange = checkerDelegate.spellServer(spellServer, findMisspelledWordIn: "text \\texmacro bar", language: "English", wordCount: &dummyCounter, countOnly: false)
        XCTAssert(resRange.location == NSNotFound)
    }

    func testNonAlphabets() {
        var dummyCounter: Int = 0
        let resRange = checkerDelegate.spellServer(spellServer, findMisspelledWordIn: "こんにちは", language: "English", wordCount: &dummyCounter, countOnly: false)
        XCTAssert(resRange.location == NSNotFound)
    }

    func testCorrectGroupCheck() {
        var dummyCounter: Int = 0
        let res = checkerDelegate.spellServer(spellServer, check: "valid string", offset: 0, types: NSTextCheckingResult.CheckingType.spelling.rawValue, orthography: nil, wordCount: &dummyCounter)
        XCTAssert(res == nil)
        XCTAssert(dummyCounter == 2)
    }

    func testIgnoreCJKGroupCheck() {
        var dummyCounter: Int = 0
        let res = checkerDelegate.spellServer(spellServer, check: "こんにちは", offset: 0, types: NSTextCheckingResult.CheckingType.spelling.rawValue, orthography: nil, wordCount: &dummyCounter)
        XCTAssert(res == nil)
    }
    
    func testMisspellAfterCJK() {
        var dummyCounter: Int = 0
        let res = checkerDelegate.spellServer(spellServer, check: "こんにちは invvalid", offset: 0, types: NSTextCheckingResult.CheckingType.spelling.rawValue, orthography: nil, wordCount: &dummyCounter)
        XCTAssert((res != nil) && (res!.count == 1))
        XCTAssert(dummyCounter == 1)
        XCTAssert(res![0].range.location == ("こんにちは " as NSString).length)
    }
    
    func testIgnoreTexGroupCheck() {
        var dummyCounter: Int = 0
        let res = checkerDelegate.spellServer(spellServer, check: "\\mathbb strring", offset: 0, types: NSTextCheckingResult.CheckingType.spelling.rawValue, orthography: nil, wordCount: &dummyCounter)
        XCTAssert((res != nil) && (res!.count == 1))
        XCTAssert(dummyCounter == 1)
    }

    func testAfterNewlineCheck() {
        var dummyCounter: Int = 0
        let res = checkerDelegate.spellServer(spellServer, check: "an my\nstrring", offset: 0, types: NSTextCheckingResult.CheckingType.spelling.rawValue, orthography: nil, wordCount: &dummyCounter)
        XCTAssert((res != nil) && (res!.count == 1))
        XCTAssert(dummyCounter == 2)
        XCTAssert((res![0].range.location == 6) && (res![0].range.length == 7))
    }

    func testIncorrectGroupCheck() {
        var dummyCounter: Int = 0
        let res = checkerDelegate.spellServer(spellServer, check: "new invalidd string baddy", offset: 0, types: NSTextCheckingResult.CheckingType.spelling.rawValue, orthography: nil, wordCount: &dummyCounter)
        XCTAssert((res != nil) && (res!.count == 2))
        XCTAssert(res![0].resultType == NSTextCheckingResult.CheckingType.spelling)
        XCTAssert(NSEqualRanges(res![0].range, NSRange(location: 4, length: 8)))
        XCTAssert(res![1].resultType == NSTextCheckingResult.CheckingType.spelling)
        XCTAssert(NSEqualRanges(res![1].range, NSRange(location: 20, length: 5)))
        XCTAssert(dummyCounter == 1)
    }
    
    func testCheckOffset() {
        var dummyCounter: Int = 0
        let res = checkerDelegate.spellServer(spellServer, check: "strring", offset: 5, types: NSTextCheckingResult.CheckingType.spelling.rawValue, orthography: nil, wordCount: &dummyCounter)
        XCTAssert((res != nil) && (res!.count == 1))
        XCTAssert(dummyCounter == 0)
        XCTAssert((res![0].range.location == 5) && (res![0].range.length == 7))
    }

    func testLearnSession() {
        var dummyCounter: Int = 0
        let res = checkerDelegate.spellServer(spellServer, check: "strrring", offset: 0, types: NSTextCheckingResult.CheckingType.spelling.rawValue, orthography: nil, wordCount: &dummyCounter)
        XCTAssert((res != nil) && (res!.count == 1))
        XCTAssert(dummyCounter == 0)
        XCTAssert((res![0].range.location == 0) && (res![0].range.length == 8))
        
        checkerDelegate.spellServer(spellServer, didLearnWord: "strrring", inLanguage:"English")

        let res2 = checkerDelegate.spellServer(spellServer, check: "strrring", offset: 0, types: NSTextCheckingResult.CheckingType.spelling.rawValue, orthography: nil, wordCount: &dummyCounter)
        XCTAssert((res2 == nil) || (res2!.count == 0))
        XCTAssert(dummyCounter == 1)
    }

    func testASpellLib() {
        guard let spell_checker = checkerDelegate.aspell_spell_checkers["en"] else {
            XCTFail()
            return
        }
        
        var as_res = aspell_speller_check(spell_checker, "beedybaady", -1)
        XCTAssert(as_res == 0)
        
        as_res = aspell_speller_check(spell_checker, "bar", -1)
        XCTAssert(as_res == 1)
    }

    func testFindMissMethod() {
        var wordPtr: Int = 0
        let theRange = checkerDelegate.spellServer(spellServer, findMisspelledWordIn: "few baddybaddywordy", language: "English", wordCount: &wordPtr, countOnly: false)
        XCTAssert(NSEqualRanges(theRange, NSRange(location: 4, length: 15)))
    }
    
    func testSuggMethod() {
        let suggs = checkerDelegate.spellServer(spellServer, suggestGuessesForWord: "takke", inLanguage: "English")
        XCTAssert(suggs != nil)
        XCTAssert(suggs![0] == "take")
    }

    func testListSync() {
        let testBundle = Bundle(for: MakoSpellCheckerUITests.self)
        let test1Path = testBundle.path(forResource: "test1", ofType: "txt")
        let test2Path = testBundle.path(forResource: "test2", ofType: "txt")
        XCTAssert(test1Path != nil && test2Path != nil)
        XCTAssert(syncPersonalWordList(checkerDelegate.aspell_spell_checkers["en"], sysListPath: test1Path!, aspellListPath: test2Path!) == true)
    }
    
    func testHexDump() {
        let testStr = "abc"
        let dumpStr = hexDump(testStr.utf8)
        XCTAssert(dumpStr == "61 62 63")
    }
    func testLangCode() {
        XCTAssert(LanguageCodeHandler.convertLangCode("en") == "English")
        XCTAssert(LanguageCodeHandler.convertLangCode("en_US") == "English")
        XCTAssert(LanguageCodeHandler.convertLangCode("de") == "German")
        XCTAssert(LanguageCodeHandler.langCode(for: "English") == "en")
    }
}

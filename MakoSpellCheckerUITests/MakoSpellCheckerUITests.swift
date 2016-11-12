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
    
    func testASpellLib() {
        guard let spell_checker = checkerDelegate.spell_checker else {
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
    
    func testASpellCorrect() {
        let testStr = "good\n"
        let testData = testStr.data(using: String.Encoding.utf8)
        let expectation = self.expectation(description:"test aspell process completed")
        let outHandler = {(handle: FileHandle) -> Void in
            let outData = handle.availableData
            let outStr = String(data: outData, encoding: String.Encoding.utf8)
            
            if (outStr?.substring(to: (outStr?.index(after: (outStr?.startIndex)!))!) == "*") {
                handle.closeFile()
                expectation.fulfill()
            }
        }
        XCTAssertNotNil(checkerDelegate.aSpellInputPipe)
        checkerDelegate.aSpellOutputPipe?.fileHandleForReading.readabilityHandler = outHandler
        checkerDelegate.aSpellInputPipe?.fileHandleForWriting.write(testData!)
        
        self.waitForExpectations(timeout: 3, handler: {(error: Error?) -> Void in
            if ((error) != nil) {
                XCTFail("aspell process failed.")
            }
        })
    }
    
    func testASpellInorrect() {
        let testStr = "baddybaddywordy\n"
        let testData = testStr.data(using: String.Encoding.utf8)
        let expectation = self.expectation(description:"test aspell process completed")
        let outHandler = {(handle: FileHandle) -> Void in
            let outData = handle.availableData
            let outStr = String(data: outData, encoding: String.Encoding.utf8)
            
            if (outStr?.substring(to: (outStr?.index(after: (outStr?.startIndex)!))!) == "&") {
                NSLog("Got suggestion for baddybaddywordy: \(outStr)")
                handle.closeFile()
                expectation.fulfill()
            }
        }
        XCTAssertNotNil(checkerDelegate.aSpellInputPipe)
        checkerDelegate.aSpellOutputPipe?.fileHandleForReading.readabilityHandler = outHandler
        checkerDelegate.aSpellInputPipe?.fileHandleForWriting.write(testData!)
        
        self.waitForExpectations(timeout: 3, handler: {(error: Error?) -> Void in
            if ((error) != nil) {
                XCTFail("aspell process failed.")
            }
        })
    }
    
}

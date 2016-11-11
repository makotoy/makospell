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
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var dummyCounter: Int = 0
        let resRange = checkerDelegate.spellServer(spellServer, findMisspelledWordIn: "foo bar", language: "English", wordCount: &dummyCounter, countOnly: false)
        XCTAssert(NSEqualRanges(resRange, NSRange(location: 0, length: 3)))
    }
    
    func testPooCheck() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var dummyCounter: Int = 0
        let resRange = checkerDelegate.spellServer(spellServer, findMisspelledWordIn: "poo bar", language: "English", wordCount: &dummyCounter, countOnly: false)
        XCTAssert(resRange.location == NSNotFound)
    }
    
    func testASpellLib() {
        guard let spell_checker = checkerDelegate.spell_checker else {
            XCTFail()
            return
        }
        
        let as_res = aspell_speller_check(spell_checker, "foo", 3)
        XCTAssert(as_res != 0)
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

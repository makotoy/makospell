//
//  MakoSpellCheckerTests.swift
//  MakoSpellCheckerTests
//
//  Created by Makoto Yamashita on ’16.10.30.
//  Copyright © 2016–2017 Makoto Yamashita. All rights reserved.
//

import XCTest
@testable import MakoSpellChecker
//import MYSpellCheckerDelegate

class MakoSpellCheckerTests: XCTestCase {
    var spellServer: NSSpellServer!
    var checkerDelegate: MYSpellCheckerDelegate!
    
    override func setUp() {
        super.setUp()
        spellServer = NSSpellServer()
        checkerDelegate = MYSpellCheckerDelegate()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTrue() {
        XCTAssert(true)
    }
    
//    func testFooCapture() {
//        var dummyCounter: Int = 0
//        let resRange = checkerDelegate.spellServer(spellServer, findMisspelledWordIn: "foo bar", language: "en", wordCount: &dummyCounter, countOnly: false)
//        XCTAssert(NSEqualRanges(resRange, NSRange(location: 0, length: 3)))
//    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
//    
}

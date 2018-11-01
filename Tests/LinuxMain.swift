import XCTest

import treeTests

var tests = [XCTestCaseEntry]()
tests += treeTests.allTests()
XCTMain(tests)